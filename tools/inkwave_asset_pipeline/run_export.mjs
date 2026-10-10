import {createServer} from 'node:http';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {dirname,resolve,extname} from 'node:path';
import {fileURLToPath} from 'node:url';
const HERE=dirname(fileURLToPath(import.meta.url));
const project=resolve(HERE,'../..');
const output=resolve(project,'gameplay/packages/monsters/monster_inkwave');
const {chromium}=await import(process.env.PLAYWRIGHT_MODULE||'/Users/bytedance/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright/index.mjs');
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json'};
const server=createServer(async(req,res)=>{if(req.url==='/favicon.ico'){res.statusCode=204;res.end();return;}try{const path=resolve(HERE,'.'+decodeURIComponent(req.url.split('?')[0]));if(!path.startsWith(HERE+'/'))throw Error('outside root');const data=await readFile(path);res.setHeader('Content-Type',mime[extname(path)]||'application/octet-stream');res.end(data);}catch(e){res.statusCode=404;res.end(String(e));}});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true,args:['--use-angle=metal','--enable-gpu','--ignore-gpu-blocklist'],timeout:180000});
try{const page=await browser.newPage({viewport:{width:1024,height:1024}});const shaderErrors=[];page.on('console',m=>{console.log(m.type(),m.text());if(m.text().includes('Shader Error')||m.text().includes('INVALID_OPERATION'))shaderErrors.push(m.text());});page.on('pageerror',e=>console.error('PAGE',e.stack));await page.exposeFunction('saveAsset',async(name,b64)=>{const path=resolve(output,name);if(!path.startsWith(output+'/'))throw Error('outside output');await mkdir(dirname(path),{recursive:true});await writeFile(path,Buffer.from(b64,'base64'));console.log('saved',name);});await page.goto(`http://127.0.0.1:${server.address().port}/export.html`);await page.waitForFunction(()=>window.exportDone||window.exportError,{timeout:1200000});const status=await page.evaluate(()=>({done:window.exportDone,error:window.exportError}));console.log(JSON.stringify(status));if(status.error)throw Error(status.error);if(shaderErrors.length)throw Error('Shader compilation failed: '+shaderErrors[0]);}finally{await browser.close();server.close();}
