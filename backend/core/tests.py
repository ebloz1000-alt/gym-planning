from django.test import TestCase


class ApiIntegrationTests(TestCase):
    def test_health_endpoint_is_available(self):
        response = self.client.get('/api/health/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['status'], 'ok')

    def test_cors_headers_allow_frontend_origin(self):
        response = self.client.options(
            '/api/health/',
            HTTP_ORIGIN='http://localhost:3000',
            HTTP_ACCESS_CONTROL_REQUEST_METHOD='GET',
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn('Access-Control-Allow-Origin', response.headers)
