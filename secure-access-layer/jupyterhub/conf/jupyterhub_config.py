c = get_config()

c.JupyterHub.authenticator_class = 'oauthenticator.generic.GenericOAuthenticator'

c.GenericOAuthenticator.client_id = 'jupyterhub-client'
c.GenericOAuthenticator.client_secret = 'cx5pp5PWGzJBHWDiFGSCwaXTHCWOW1qo'
c.GenericOAuthenticator.oauth_callback_url = 'https://jupyterhub.internal/hub/oauth_callback'

c.GenericOAuthenticator.authorize_url = 'https://keycloak.internal/realms/flower-realm/protocol/openid-connect/auth'
c.GenericOAuthenticator.token_url     = 'https://keycloak.internal/realms/flower-realm/protocol/openid-connect/token'
c.GenericOAuthenticator.userdata_url  = 'https://keycloak.internal/realms/flower-realm/protocol/openid-connect/userinfo'

c.GenericOAuthenticator.scope = ['openid', 'profile', 'email', 'groups']
c.GenericOAuthenticator.username_claim = 'preferred_username'
c.GenericOAuthenticator.allowed_groups = ['researcher', 'admin']

c.ConfigurableHTTPProxy.command = ['/usr/bin/configurable-http-proxy', '--ssl-key=/opt/jupyterhub/certs/jupyterhub.internal.key', '--ssl-cert=/opt/jupyterhub/certs/jupyterhub.internal.crt']

c.Spawner.default_url = '/lab'
