from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    environment: str = "development"
    allowed_origins: str = "http://localhost:5173"

    model_config = {"env_file": ".env"}


settings = Settings()
