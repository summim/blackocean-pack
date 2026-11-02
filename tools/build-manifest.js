#!/usr/bin/env node
// pack/ 폴더를 훑어 manifest.json 을 만듭니다.
//   node tools/build-manifest.js            ← pack.config.json 의 설정 사용
// 그런 다음 git commit + push 하면 시청자 접속기가 다음 실행 때 자동으로 받아요.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const root = path.join(__dirname, '..');
const cfg = JSON.parse(fs.readFileSync(path.join(root, 'pack.config.json'), 'utf8'));
const packDir = path.join(root, 'pack');

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}
const sha1 = (f) => crypto.createHash('sha1').update(fs.readFileSync(f)).digest('hex');

const files = walk(packDir).map((f) => {
  const rel = path.relative(packDir, f).split(path.sep).join('/');
  const once = (cfg.onceFiles || []).includes(rel);
  return {
    path: rel,
    url: `${cfg.rawBase.replace(/\/$/, '')}/pack/${rel.split('/').map(encodeURIComponent).join('/')}`,
    sha1: sha1(f), size: fs.statSync(f).size, ...(once ? { once: true } : {}),
  };
}).sort((a, b) => a.path.localeCompare(b.path));

const prev = (() => { try { return JSON.parse(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8')); } catch { return {}; } })();
const manifest = {
  version: (prev.version || 0) + 1,
  updatedAt: new Date().toISOString(),
  mc: cfg.mc, neoforge: cfg.neoforge, server: cfg.server,
  notes: cfg.notes || '',
  managedDirs: cfg.managedDirs || ['mods'],
  files,
};
fs.writeFileSync(path.join(root, 'manifest.json'), JSON.stringify(manifest, null, 2));
console.log(`manifest.json v${manifest.version} — 파일 ${files.length}개`);
for (const f of files) console.log('  ' + f.path + (f.once ? ' (once)' : ''));
