const fs = require('fs');
const path = require('path');
const dir = 'chivimarket_front/lib';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.dart'));
files.forEach(f => {
    const p = path.join(dir, f);
    let c = fs.readFileSync(p, 'utf8');
    c = c.replace(/const\s+([A-Z][a-zA-Z0-9_]*\()/g, '$1');
    fs.writeFileSync(p, c);
});
console.log('Fixed all widget constants');
