import os

import uvicorn
from app.core.app import create_app
from app.core.config import get_settings

app = create_app()
settings = get_settings()

if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "3010"))
    uvicorn.run("main:app", host=host, port=port, reload=settings.local_reload)
