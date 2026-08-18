from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes.analyze import router as analyze_router
from routes.auth import router as auth_router
from routes.doctors import router as doctors_router
from routes.health import router as health_router
from routes.patients import router as patients_router
from security import is_default_jwt_secret

app = FastAPI(title="Stroke Recovery Monitoring API", version="1.0.0")

app.add_middleware(
	CORSMiddleware,
	allow_origins=["*"],
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
)


@app.on_event("startup")
def startup_checks() -> None:
	if is_default_jwt_secret():
		# Warning only: keep local development unblocked.
		print("WARNING: JWT_SECRET is using the default development value.")

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(patients_router)
app.include_router(doctors_router)
app.include_router(analyze_router)
