"""Capture actual provisioned Grafana UI on the disposable acceptance runner."""
import json, shutil
from pathlib import Path
from playwright.sync_api import sync_playwright
password=Path('.local/secrets/grafana_password').read_text().strip()
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=shutil.which('google-chrome'),headless=True,args=['--no-sandbox'])
    context=browser.new_context(viewport={'width':1440,'height':1500},device_scale_factor=1)
    response=context.request.post('http://localhost:3000/login',data={'user':'admin','password':password})
    assert response.ok, 'Grafana login failed'
    page=context.new_page()
    page.goto('http://localhost:3000/d/payflow-ops',wait_until='networkidle')
    page.get_by_text('Postgres available',exact=True).wait_for()
    page.wait_for_timeout(4000)
    Path('.local/evidence').mkdir(parents=True,exist_ok=True)
    page.screenshot(path='.local/evidence/grafana-dashboard.png',full_page=True)
    assert page.get_by_text('Reconciliation mismatches',exact=True).count() == 1
    browser.close()
print('Captured actual Grafana dashboard; business panels are expected to have no data.')
