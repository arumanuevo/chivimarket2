const fs = require('fs');
const path = require('path');
const dir = 'chivimarket_front/lib';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.dart'));
files.forEach(f => {
    const p = path.join(dir, f);
    let c = fs.readFileSync(p, 'utf8');
    c = c.replace(/const (Icon|Text|TextStyle|InputDecoration|BoxDecoration|BorderSide|SizedBox)/g, '$1');
    fs.writeFileSync(p, c);
});
console.log('Fixed constants');
