const fs = require('fs');
const path = 'd:/wftech/projets/web/wftech/src/app/solutions/zehouse/admin/page.tsx';

let code = fs.readFileSync(path, 'utf8');

// Search and fix any duplicate state declarations
const targetStr = `const [advertisersList, setAdvertisersList] = useState`;
const firstIdx = code.indexOf(targetStr);
const lastIdx = code.lastIndexOf(targetStr);

console.log('firstIdx:', firstIdx, 'lastIdx:', lastIdx);

if (firstIdx !== -1 && lastIdx !== -1 && firstIdx !== lastIdx) {
  // Find line boundaries for the second declaration block
  const blockStart = code.lastIndexOf('\n  // Advertisers & Partner Ads State', lastIdx);
  const blockEnd = code.indexOf('\n', code.indexOf('useState', code.indexOf('applicationsList', lastIdx)));
  
  console.log('Removing from', blockStart, 'to', blockEnd);
  if (blockStart !== -1 && blockEnd !== -1) {
    code = code.substring(0, blockStart) + code.substring(blockEnd);
    fs.writeFileSync(path, code, 'utf8');
    console.log('Deduplicated successfully!');
  }
}
