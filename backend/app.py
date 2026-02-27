"""
CarGuardian Flask Backend
AI-powered Vehicle Damage Detection & Fleet Management API
"""

import os
import logging
import base64
import json
import uuid
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore, storage, auth
from openai import OpenAI
import re

# ── Load environment ──────────────────────────────────────────────────────────
load_dotenv()

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("carguardian")

# ── Firebase init ─────────────────────────────────────────────────────────────
def init_firebase():
    if not firebase_admin._apps:
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase_credentials.json")
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
        else:
            cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
            if not cred_json:
                raise RuntimeError("No Firebase credentials found.")
            cred_dict = json.loads(cred_json)
            cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred, {
            "storageBucket": os.getenv("FIREBASE_STORAGE_BUCKET")
        })
        log.info("Firebase initialised successfully.")

init_firebase()
db     = firestore.client()
bucket = storage.bucket()
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ── Flask app ─────────────────────────────────────────────────────────────────
app = Flask(__name__)
CORS(app, origins="*")

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def verify_token(req):
    auth_header = req.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    id_token = auth_header.split(" ", 1)[1]
    try:
        decoded = auth.verify_id_token(id_token)
        return decoded["uid"]
    except Exception as e:
        log.warning("Token verification failed: %s", e)
        return None


def require_auth(fn):
    from functools import wraps
    @wraps(fn)
    def wrapper(*args, **kwargs):
        uid = verify_token(request)
        if not uid:
            return jsonify({"error": "Unauthorised"}), 401
        return fn(uid, *args, **kwargs)
    return wrapper


def upload_image_to_storage(image_bytes, path):
    blob = bucket.blob(path)
    blob.upload_from_string(image_bytes, content_type="image/jpeg")
    blob.make_public()
    return blob.public_url


def calculate_health_score(damage_reports, service_records):
    score = 100
    severity_penalties = {"minor": 5, "moderate": 15, "severe": 30}
    for report in damage_reports:
        sev = report.get("severity_level", "").lower()
        score -= severity_penalties.get(sev, 0)
    if service_records:
        latest = max(service_records, key=lambda r: r.get("service_date", ""))
        last_date_str = latest.get("service_date", "")
        if last_date_str:
            try:
                last_date = datetime.fromisoformat(last_date_str)
                days_since = (datetime.utcnow() - last_date).days
                if days_since > 180:
                    score -= 10
            except ValueError:
                pass
    return max(0, min(100, score))

# ─────────────────────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────────────────────

@app.route("/", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "CarGuardian API", "version": "1.0.0"})

@app.route("/health", methods=["GET"])
def health_detailed():
    return jsonify({
        "status": "ok",
        "firebase": "connected",
        "openai": "configured" if os.getenv("OPENAI_API_KEY") else "missing",
        "timestamp": datetime.utcnow().isoformat()
    })

# ─────────────────────────────────────────────────────────────────────────────
# AI DAMAGE DETECTION
# ─────────────────────────────────────────────────────────────────────────────

@app.route("/api/damage/analyze", methods=["POST"])
@require_auth
def analyze_damage(uid):
    """
    multipart/form-data:
      image       : file
      vehicle_id  : string
      language    : en | hi | ta
    """
    vehicle_id = request.form.get("vehicle_id")
    language   = request.form.get("language", "en")

    if "image" not in request.files:
        return jsonify({"error": "No image provided"}), 400
    if not vehicle_id:
        return jsonify({"error": "vehicle_id is required"}), 400

    image_file  = request.files["image"]
    image_bytes = image_file.read()

    # Upload to Firebase Storage
    timestamp    = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    storage_path = f"damage_images/{uid}/{vehicle_id}/{timestamp}.jpg"
    try:
        image_url = upload_image_to_storage(image_bytes, storage_path)
        log.info("Image uploaded: %s", storage_path)
    except Exception as e:
        log.error("Storage upload failed: %s", e)
        return jsonify({"error": "Image upload failed"}), 500

    # OpenAI Vision
    language_map = {"hi": "Hindi", "ta": "Tamil", "en": "English"}
    lang_name    = language_map.get(language, "English")
    encoded_img  = base64.b64encode(image_bytes).decode("utf-8")

    system_prompt = f"""You are an expert automotive damage assessment AI.
Analyse the provided vehicle image and return a structured JSON response.
Respond ONLY in {lang_name}.
Return ONLY valid JSON — no markdown, no extra text.

Required JSON schema:
{{
  "damage_type": "string",
  "severity_level": "Minor | Moderate | Severe",
  "affected_part": "string",
  "repair_suggestion": "string",
  "estimated_repair_cost": {{"min": 0, "max": 0, "currency": "INR"}},
  "parts_possibly_required": [],
  "additional_notes": "string",
  "confidence_score": 0
}}"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": [
                    {"type": "text", "text": "Analyse this vehicle image for damage."},
                    {"type": "image_url", "image_url": {
                        "url": f"data:image/jpeg;base64,{encoded_img}",
                        "detail": "high"
                    }}
                ]}
            ],
            max_tokens=1024,
            temperature=0.2,
        )
        raw = response.choices[0].message.content.strip()
        raw = re.sub(r"^```(?:json)?\s*", "", raw)
        raw = re.sub(r"\s*```$", "", raw)
        analysis = json.loads(raw)
        log.info("OpenAI analysis done for vehicle %s", vehicle_id)
    except json.JSONDecodeError as e:
        log.error("JSON parse error: %s  raw=%s", e, raw[:200])
        return jsonify({"error": "AI response parse error"}), 500
    except Exception as e:
        log.error("OpenAI API error: %s", e)
        return jsonify({"error": "AI analysis failed", "detail": str(e)}), 500

    # Save to Firestore
    report_id  = str(uuid.uuid4())
    report_doc = {
        "report_id": report_id,
        "vehicle_id": vehicle_id,
        "image_url": image_url,
        "analysis": analysis,
        "created_at": datetime.utcnow().isoformat(),
        "language": language,
    }
    try:
        reports_ref = (
            db.collection("users").document(uid)
            .collection("fleet").document(vehicle_id)
            .collection("damageReports")
        )
        reports_ref.document(report_id).set(report_doc)

        vehicle_ref = (
            db.collection("users").document(uid)
            .collection("fleet").document(vehicle_id)
        )
        vehicle_snap = vehicle_ref.get()
        if vehicle_snap.exists:
            existing_cost = vehicle_snap.to_dict().get("total_repair_cost", 0) or 0
            new_cost = existing_cost + analysis.get("estimated_repair_cost", {}).get("max", 0)
            vehicle_ref.update({"total_repair_cost": new_cost})

        all_reports  = [r.to_dict().get("analysis", {}) for r in reports_ref.stream()]
        all_services = [s.to_dict() for s in (
            db.collection("users").document(uid)
            .collection("fleet").document(vehicle_id)
            .collection("serviceRecords").stream()
        )]
        score = calculate_health_score(all_reports, all_services)
        vehicle_ref.update({"vehicle_health_score": score})
        log.info("Damage report %s saved.", report_id)
    except Exception as e:
        log.error("Firestore write failed: %s", e)

    return jsonify({
        "success": True,
        "report_id": report_id,
        "image_url": image_url,
        "analysis": analysis,
    }), 200

# ─────────────────────────────────────────────────────────────────────────────
# VOICE / CHAT ASSISTANT
# ─────────────────────────────────────────────────────────────────────────────

@app.route("/api/assistant/query", methods=["POST"])
@require_auth
def assistant_query(uid):
    data       = request.get_json(force=True)
    question   = data.get("question", "").strip()
    vehicle_id = data.get("vehicle_id")
    language   = data.get("language", "en")

    if not question:
        return jsonify({"error": "question is required"}), 400

    context = ""
    if vehicle_id:
        try:
            v = (
                db.collection("users").document(uid)
                .collection("fleet").document(vehicle_id).get()
            )
            if v.exists:
                d = v.to_dict()
                context = (
                    f"Vehicle: {d.get('name','')} {d.get('brand','')} {d.get('model','')} | "
                    f"Reg: {d.get('registration_number','')} | "
                    f"Health: {d.get('vehicle_health_score',100)}/100 | "
                    f"Last Service: {d.get('last_service_date','')} | "
                    f"Insurance Expiry: {d.get('insurance_expiry_date','')} | "
                    f"Total Repair Cost: INR {d.get('total_repair_cost',0)}"
                )
        except Exception as e:
            log.warning("Could not fetch vehicle context: %s", e)

    language_map = {"hi": "Hindi", "ta": "Tamil", "en": "English"}
    lang_name    = language_map.get(language, "English")
    system_msg   = (
        f"You are CarGuardian, a friendly vehicle assistant. Answer in {lang_name}. "
        f"Be concise.\nVehicle context: {context}"
        if context else
        f"You are CarGuardian, a friendly vehicle assistant. Answer in {lang_name}. Be concise."
    )

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": question}
            ],
            max_tokens=512,
            temperature=0.5,
        )
        answer = response.choices[0].message.content.strip()
    except Exception as e:
        log.error("Assistant error: %s", e)
        return jsonify({"error": "Assistant failed", "detail": str(e)}), 500

    return jsonify({"answer": answer, "question": question}), 200

# ─────────────────────────────────────────────────────────────────────────────
# FLEET ANALYTICS
# ─────────────────────────────────────────────────────────────────────────────

@app.route("/api/fleet/summary", methods=["GET"])
@require_auth
def fleet_summary(uid):
    try:
        vehicles          = list(db.collection("users").document(uid).collection("fleet").stream())
        total_repair_cost = 0
        total_vehicles    = len(vehicles)
        upcoming_services = []
        upcoming_insurance = []
        health_scores     = []
        today             = datetime.utcnow().date()

        for v in vehicles:
            d = v.to_dict()
            total_repair_cost += d.get("total_repair_cost", 0) or 0
            health_scores.append(d.get("vehicle_health_score", 100) or 100)

            svc_str = d.get("last_service_date", "")
            if svc_str:
                try:
                    svc = datetime.fromisoformat(svc_str).date()
                    nxt = svc.replace(year=svc.year + 1)
                    days = (nxt - today).days
                    if 0 <= days <= 30:
                        upcoming_services.append({"vehicle_id": v.id, "name": d.get("name",""), "due_in_days": days})
                except ValueError:
                    pass

            ins_str = d.get("insurance_expiry_date", "")
            if ins_str:
                try:
                    ins = datetime.fromisoformat(ins_str).date()
                    days = (ins - today).days
                    if 0 <= days <= 30:
                        upcoming_insurance.append({"vehicle_id": v.id, "name": d.get("name",""), "expires_in_days": days})
                except ValueError:
                    pass

        avg_health = int(sum(health_scores) / len(health_scores)) if health_scores else 100
        return jsonify({
            "total_vehicles": total_vehicles,
            "total_repair_cost": total_repair_cost,
            "average_health_score": avg_health,
            "upcoming_services": upcoming_services,
            "upcoming_insurance_renewals": upcoming_insurance,
        }), 200
    except Exception as e:
        log.error("Fleet summary error: %s", e)
        return jsonify({"error": str(e)}), 500

# ─────────────────────────────────────────────────────────────────────────────
# SERVICE RECORDS
# ─────────────────────────────────────────────────────────────────────────────

@app.route("/api/fleet/<vehicle_id>/service", methods=["POST"])
@require_auth
def add_service_record(uid, vehicle_id):
    data      = request.get_json(force=True)
    record_id = str(uuid.uuid4())
    record    = {
        "record_id": record_id,
        "vehicle_id": vehicle_id,
        "service_date": data.get("service_date", datetime.utcnow().isoformat()),
        "service_type": data.get("service_type", "General Service"),
        "cost": data.get("cost", 0),
        "notes": data.get("notes", ""),
        "mileage_at_service": data.get("mileage_at_service", 0),
        "created_at": datetime.utcnow().isoformat(),
    }
    try:
        (
            db.collection("users").document(uid)
            .collection("fleet").document(vehicle_id)
            .collection("serviceRecords").document(record_id)
            .set(record)
        )
        vehicle_ref = (
            db.collection("users").document(uid)
            .collection("fleet").document(vehicle_id)
        )
        vehicle_ref.update({
            "last_service_date": record["service_date"],
            "total_repair_cost": firestore.Increment(record["cost"])
        })
        return jsonify({"success": True, "record_id": record_id}), 201
    except Exception as e:
        log.error("Service record error: %s", e)
        return jsonify({"error": str(e)}), 500

# ─────────────────────────────────────────────────────────────────────────────
# ERROR HANDLERS
# ─────────────────────────────────────────────────────────────────────────────

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(e):
    log.error("Unhandled exception: %s", e)
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=False)
