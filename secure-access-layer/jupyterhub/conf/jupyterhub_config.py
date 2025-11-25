# /home/ghost/workspace/internship_project/federated_learning_secure_implementation/secure-access-layer/jupyterhub/conf/jupyterhub_config.py

c = get_config()

c.JupyterHub.log_level = "DEBUG"
c.Spawner.debug = True

c.JupyterHub.bind_url = "http://0.0.0.0:8000"
c.ConfigurableHTTPProxy.api_url = "http://127.0.0.1:8001"
c.JupyterHub.hub_bind_url = "http://127.0.0.1:8081"

c.JupyterHub.authenticator_class = "jupyterhub.auth.PAMAuthenticator"
c.Authenticator.allow_all = True

# c.JupyterHub.authenticator_class = "oauthenticator.generic.GenericOAuthenticator"
# c.GenericOAuthenticator.client_id = "jupyterhub-client"
# c.GenericOAuthenticator.client_secret = "cx5pp5PWGzJBHWDiFGSCwaXTHCWOW1qo"
# c.GenericOAuthenticator.oauth_callback_url = (
#     "https://jupyterhub.internal/hub/oauth_callback"
# )
# c.GenericOAuthenticator.authorize_url = (
#     "https://keycloak.internal/realms/flower-realm/protocol/openid-connect/auth"
# )
# c.GenericOAuthenticator.token_url = (
#     "https://keycloak.internal/realms/flower-realm/protocol/openid-connect/token"
# )
# c.GenericOAuthenticator.userdata_url = (
#     "https://keycloak.internal/realms/flower-realm/protocol/openid-connect/userinfo"
# )
# c.GenericOAuthenticator.scope = ["openid", "profile", "email", "groups"]
# c.GenericOAuthenticator.username_claim = "preferred_username"

# # Work-around: allow all authenticated users
# c.GenericOAuthenticator.allow_all = True

c.JupyterHub.proxy_auth_token = "very-secret-proxy-token"
c.ConfigurableHTTPProxy.command = [
    "/usr/local/bin/configurable-http-proxy",
    "--ip=0.0.0.0",
    "--port=8000",
    "--api-ip=127.0.0.1",
    "--api-port=8001",
    "--error-target",
    "http://127.0.0.1:8081/hub/error",
    # "--ssl-key=/opt/jupyterhub/certs/jupyterhub.internal.key",
    # "--ssl-cert=/opt/jupyterhub/certs/jupyterhub.internal.crt",
]

c.Spawner.default_url = "/lab"

# # /home/ghost/workspace/internship_project/federated_learning_secure_implementation/secure-access-layer/jupyterhub/conf/jupyterhub_config.py

# # ------------------------------------------------------------
# # Global JupyterHub-level settings
# # ------------------------------------------------------------
# c = get_config()

# # Set log level for debugging
# c.JupyterHub.log_level = "DEBUG"
# c.Spawner.debug = True

# # Bind JupyterHub components to localhost interfaces
# c.JupyterHub.bind_url = "http://127.0.0.1:8000"  # The public URL JupyterHub listens on
# c.ConfigurableHTTPProxy.api_url = "http://127.0.0.1:8001"  # Proxy API endpoint
# c.JupyterHub.hub_bind_url = "http://127.0.0.1:8081"  # Hub internal endpoint

# # ------------------------------------------------------------
# # OAuth2 / OIDC Authenticator settings for Keycloak
# # ------------------------------------------------------------
# c.JupyterHub.authenticator_class = "oauthenticator.generic.GenericOAuthenticator"

# # OAuth2 client credentials (must match the client in Keycloak)
# c.GenericOAuthenticator.client_id = "jupyterhub-client"
# c.GenericOAuthenticator.client_secret = "<YOUR_CLIENT_SECRET>"

# # Callback URL defined in Keycloak client settings
# c.GenericOAuthenticator.oauth_callback_url = (
#     "https://jupyterhub.internal/hub/oauth_callback"
# )

# # Keycloak endpoints for authorization and token issuance
# c.GenericOAuthenticator.authorize_url = (
#     "https://keycloak.internal/realms/flower-realm/protocol/openid-connect/auth"
# )
# c.GenericOAuthenticator.token_url = (
#     "https://keycloak.internal/realms/flower-realm/protocol/openid-connect/token"
# )
# c.GenericOAuthenticator.userdata_url = (
#     "https://keycloak.internal/realms/flower-realm/protocol/openid-connect/userinfo"
# )

# # Scopes requested and user info claims mapping
# c.GenericOAuthenticator.scope = ["openid", "profile", "email", "groups"]
# c.GenericOAuthenticator.username_claim = "preferred_username"

# # ------------------------------------------------------------
# # Group-based access control
# # ------------------------------------------------------------
# # Enable group membership support
# c.GenericOAuthenticator.manage_groups = True

# # Map the groups claim key in auth_state (if your token uses "groups")
# c.GenericOAuthenticator.auth_state_groups_key = "groups"

# # Only users in these groups will be allowed login
# c.GenericOAuthenticator.allowed_groups = {"researcher", "admin"}

# # Don’t use JupyterHub “roles” for now
# c.GenericOAuthenticator.manage_roles = False
# c.JupyterHub.load_roles = []  # Explicitly disable role loading

# # ------------------------------------------------------------
# # Proxy settings for TLS (JupyterHub + NGINX setup)
# # ------------------------------------------------------------
# # import os

# # c.JupyterHub.proxy_auth_token = os.environ.get("CONFIGPROXY_AUTH_TOKEN")

# c.ConfigurableHTTPProxy.command = [
#     "/usr/local/bin/configurable-http-proxy",
#     "--ip=127.0.0.1",
#     "--port=8000",
#     "--api-ip=127.0.0.1",
#     "--api-port=8001",
#     "--ssl-key=/opt/jupyterhub/certs/jupyterhub.internal.key",
#     "--ssl-cert=/opt/jupyterhub/certs/jupyterhub.internal.crt",
# ]

# # ------------------------------------------------------------
# # Default spawn URL
# # ------------------------------------------------------------
# c.Spawner.default_url = "/lab"

# # /home/ghost/workspace/internship_project/federated_learning_secure_implementation/secure-access-layer/jupyterhub/conf/jupyterhub_config.py
