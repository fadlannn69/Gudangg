import datetime

from fastapi import Security, HTTPException , Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from passlib.context import CryptContext
import jwt
from starlette import status
from sqlmodel import Session
from model.model_user import SQLModel,User,find_user , get_session


with open("ec_private.pem", "r") as f:
    PRIVATE_KEY = f.read()

with open("ec_public.pem", "r") as f:
    PUBLIC_KEY = f.read()



class AuthHandler:
    security = HTTPBearer()
    pwd_context = CryptContext(schemes=['argon2'], deprecated="auto")
    secret = 'supersecret'

    def get_password_hash(self, password):
        return self.pwd_context.hash(password)

    def verify_password(self, pwd, hashed_pwd):
        return self.pwd_context.verify(pwd, hashed_pwd)

    def encode_token(self, user_id):
        payload = {
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1),
            'iat': datetime.datetime.utcnow(),
            'sub': str(user_id)
        }
        return jwt.encode(payload, PRIVATE_KEY, algorithm='ES256')

    def decode_token(self, token):
        try:
            payload = jwt.decode(token, PUBLIC_KEY, algorithms=['ES256'])
            return payload['sub']
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail='TOKEN ANDA EXPIRED')
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail='TOKEN ANDA SALAH')


    def auth_wrapper(self, auth: HTTPAuthorizationCredentials = Security(security)):
        return self.decode_token(auth.credentials)

    def get_current_user(self, auth: HTTPAuthorizationCredentials = Security(security) , session : Session=Depends(get_session)):
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='KREDENSIAL SALAH'
        )
        username = self.decode_token(auth.credentials)
        if username is None:
            raise credentials_exception
        user = find_user(username , session)
        if user is None:
            raise credentials_exception
        return user


