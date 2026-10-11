"""Interactive loading must not perform delivery validation or send every detail."""
import http.client
import json
import os
import struct
import threading
import time
import unittest
import zlib
from unittest import mock

from test_catalog import ProjectFixture
from catalog import AssetCatalog
from server import ArtManagerServer, Handler
from thumbnails import ThumbnailCache


class LoadingTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()
        self.addCleanup(self.fixture.close)
        self.fixture.character_manifest()
        self.fixture.install_index(['chalk'])

    def test_browse_never_hashes_files_or_claims_verified_integration(self):
        catalog = AssetCatalog(self.fixture.root)
        with mock.patch('catalog._sha256', side_effect=AssertionError('browse reads full file')):
            result = catalog.scan(validate=False)
        obj = result['objects'][0]
        self.assertTrue(obj['has_generated_assets'])
        self.assertEqual('unknown', obj['integration']['verified_status'])
        self.assertEqual('unknown', obj['variants'][1]['summary']['validation_status'])
        self.assertIsNone(obj['assets'][0]['integrity']['actual'])

    def test_progress_counts_actual_work_and_validation_rechecks_changes(self):
        updates = []
        catalog = AssetCatalog(self.fixture.root)
        catalog.scan(validate=False, progress=updates.append)
        self.assertEqual(0, updates[0]['completed'])
        self.assertEqual(updates[-1]['total'], updates[-1]['completed'])
        self.assertGreater(updates[-1]['total'], 1)
        self.assertEqual(sorted(u['completed'] for u in updates), [u['completed'] for u in updates])
        self.assertEqual(0, catalog.scan()['summary']['mismatches'])
        self.fixture.file('assets/art/characters/chalk/sheet.png', b'changed content')
        self.assertEqual(1, catalog.scan()['summary']['mismatches'])

    def test_running_job_keeps_old_files_and_rejects_conflicting_refresh(self):
        server = ArtManagerServer(('127.0.0.1', 0), Handler, self.fixture.root)
        self.addCleanup(server.server_close)
        old_catalog = server.catalog
        entered, release = threading.Event(), threading.Event()
        real_scan = AssetCatalog.scan
        def delayed_scan(catalog, *args, **kwargs):
            entered.set()
            release.wait(3)
            return real_scan(catalog, *args, **kwargs)
        with mock.patch.object(AssetCatalog, 'scan', delayed_scan):
            job = server.loader.start(server.default_manifest, False)
            self.assertTrue(entered.wait(1))
            self.assertIs(old_catalog, server.catalog)
            self.assertEqual(job['id'], server.loader.start(server.default_manifest, False)['id'])
            with self.assertRaises(RuntimeError):
                server.loader.start(server.default_manifest, True)
            release.set()
            for _ in range(100):
                if server.loader.status(job['id'])['state'] != 'running':
                    break
                time.sleep(.01)
        self.assertEqual('ready', server.loader.status(job['id'])['state'])
        self.assertIsNot(old_catalog, server.catalog)

    @unittest.skipUnless(os.name == 'nt', 'Windows built-in decoder')
    def test_thumbnail_is_small_cached_invalidated_and_keeps_source(self):
        def png(red):
            def chunk(kind, data):
                return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
            return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 800, 400, 8, 6, 0, 0, 0)) +
                    chunk(b'IDAT', zlib.compress((b'\x00' + bytes([red, 40, 70, 128]) * 800) * 400)) + chunk(b'IEND', b''))
        source = self.fixture.file('design/concepts/source.png', png(10))
        original = source.read_bytes()
        cache = ThumbnailCache(self.fixture.root)
        target = cache.get(source)
        self.assertNotEqual(source, target)
        self.assertEqual((480, 240), struct.unpack('>II', target.read_bytes()[16:24]))
        self.assertEqual(original, source.read_bytes())
        self.assertEqual(target, cache.get(source))
        source.write_bytes(png(200))
        stamp = source.stat().st_mtime_ns + 1000000000
        os.utime(str(source), ns=(stamp, stamp))
        self.assertNotEqual(target, cache.get(source))

    def test_async_job_keeps_previous_catalog_until_ready_and_returns_light_index(self):
        server = ArtManagerServer(('127.0.0.1', 0), Handler, self.fixture.root)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(thread.join, 2)
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        def request(method, path, payload=None):
            connection = http.client.HTTPConnection('127.0.0.1', server.server_address[1], timeout=3)
            headers = {'X-Art-Token': server.token, 'Content-Type': 'application/json'}
            connection.request(method, path, body=json.dumps(payload) if payload is not None else None, headers=headers)
            response = connection.getresponse()
            body = json.loads(response.read().decode('utf-8'))
            connection.close()
            return response.status, body
        status, job = request('POST', '/api/load', {'validate': False})
        self.assertEqual(202, status)
        for _ in range(100):
            _, job = request('GET', '/api/load/status?id=' + job['id'])
            if job['state'] != 'running':
                break
            time.sleep(.01)
        self.assertEqual('ready', job['state'])
        self.assertEqual(job['total'], job['completed'])
        obj = job['result']['objects'][0]
        self.assertNotIn('assets', obj)
        self.assertNotIn('variants', obj)
        self.assertIn('thumbnail', obj)
        status, detail = request('GET', '/api/object?id=chalk&revision=' + job['id'])
        self.assertEqual(200, status)
        self.assertIn('variants', detail)
        status, _ = request('GET', '/api/object?id=chalk&revision=expired')
        self.assertEqual(409, status)


if __name__ == '__main__':
    unittest.main()
