const esbuild = require('esbuild');
const { existsSync, mkdirSync } = require('fs');
const { join } = require('path');

const steps = ['install', 'configure', 'resolve-pr', 'run-review', 'post-review'];

const distDir = join(__dirname, 'dist');
if (!existsSync(distDir)) {
  mkdirSync(distDir, { recursive: true });
}

for (const step of steps) {
  esbuild.buildSync({
    entryPoints: [join(__dirname, 'src', `${step}.ts`)],
    bundle: true,
    platform: 'node',
    target: 'node20',
    outfile: join(distDir, `${step}.js`),
    format: 'cjs',
    external: [],
    minify: false,
    sourcemap: false,
  });
  console.log(`Built dist/${step}.js`);
}
