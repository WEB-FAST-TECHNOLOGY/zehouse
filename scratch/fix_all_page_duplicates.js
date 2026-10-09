const fs = require('fs');
const path = 'd:/wftech/projets/web/wftech/src/app/solutions/zehouse/admin/page.tsx';

let code = fs.readFileSync(path, 'utf8');

const seenVars = new Set();
const seenFuncs = new Set();

const lines = code.split('\n');
const newLines = [];

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  
  // Check state variable match
  const varMatch = line.match(/^\s*const\s+\[([a-zA-Z0-9_]+),\s*set[a-zA-Z0-9_]+\]\s*=/);
  if (varMatch) {
    const varName = varMatch[1];
    if (seenVars.has(varName)) {
      console.log(`Removing duplicate state: ${varName} at line ${i+1}`);
      continue;
    } else {
      seenVars.add(varName);
    }
  }

  // Check function match: const handleX = ... or function handleX...
  const funcMatch = line.match(/^\s*(?:const|async\s+function|function)\s+([a-zA-Z0-9_]+)\s*=\s*(?:async\s*)?\(|^\s*async\s+function\s+([a-zA-Z0-9_]+)\s*\(/);
  if (funcMatch) {
    const funcName = funcMatch[1] || funcMatch[2];
    if (funcName && (funcName.startsWith('handle') || funcName.startsWith('fetch'))) {
      if (seenFuncs.has(funcName)) {
        console.log(`Removing duplicate function start: ${funcName} at line ${i+1}`);
        // Skip until closing brace line
        let braceCount = 0;
        let j = i;
        while (j < lines.length) {
          const l = lines[j];
          braceCount += (l.match(/\{/g) || []).length;
          braceCount -= (l.match(/\}/g) || []).length;
          if (j > i && braceCount <= 0) {
            i = j; // skip block
            break;
          }
          j++;
        }
        continue;
      } else {
        seenFuncs.add(funcName);
      }
    }
  }

  newLines.push(line);
}

fs.writeFileSync(path, newLines.join('\n'), 'utf8');
console.log('Finished deduplicating state and functions!');
