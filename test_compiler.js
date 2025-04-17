// Simple test script to validate the structure of spell compiler
// This doesn't execute the Lua code but checks its structure

const fs = require('fs');

// Read the spellCompiler.lua file
const spellCompilerContent = fs.readFileSync('spellCompiler.lua', 'utf8');

// Simple checks to verify key functions and structure
const structureChecks = [
  { name: "Has SpellCompiler table", pattern: "local SpellCompiler = {}" },
  { name: "Has mergeTables helper function", pattern: "local function mergeTables(target, source)" },
  { name: "Has compileSpell function", pattern: "function SpellCompiler.compileSpell(spellDef, keywordData)" },
  { name: "Has debugCompiled function", pattern: "function SpellCompiler.debugCompiled(compiledSpell)" },
  { name: "Creates behavior table", pattern: "behavior = {}" },
  { name: "Handles boolean keywords", pattern: "type(params) == \"boolean\"" },
  { name: "Executes behaviors", pattern: "executeAll = function(caster, target, results)" },
  { name: "Returns compiled spell", pattern: "return compiledSpell" }
];

// Check for each pattern
console.log("=== SPELL COMPILER STRUCTURE VALIDATION ===\n");

let allPassed = true;
structureChecks.forEach(check => {
  const found = spellCompilerContent.includes(check.pattern);
  console.log(`${check.name}: ${found ? 'PASSED' : 'FAILED'}`);
  if (!found) allPassed = false;
});

console.log("\nOverall validation: " + (allPassed ? "PASSED" : "FAILED"));
console.log("\n=== VALIDATION COMPLETE ===");

// Write results to file
const results = `
=== SPELL COMPILER STRUCTURE VALIDATION ===

${structureChecks.map(check => 
  `${check.name}: ${spellCompilerContent.includes(check.pattern) ? 'PASSED' : 'FAILED'}`
).join('\n')}

Overall validation: ${allPassed ? "PASSED" : "FAILED"}

=== VALIDATION COMPLETE ===
`;

fs.writeFileSync('compiler_validation_results.txt', results);