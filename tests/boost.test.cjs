const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const boost = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../Boost.js'), 'utf8'), boost);

for (const [backend, raw, enabled] of [
  ['intel', '0', true], ['intel', '1', false],
  ['cpufreq', '0', false], ['cpufreq', '1', true],
]) {
  const state = boost.parseState(`${backend}\t${raw}\n`);
  assert.equal(state.available, true);
  assert.equal(state.enabled, enabled);
  assert.equal(state.backend, backend);
  const command = boost.setCommand(backend, enabled);
  const file = backend === 'intel'
    ? '/sys/devices/system/cpu/intel_pstate/no_turbo'
    : '/sys/devices/system/cpu/cpufreq/boost';
  assert.equal(command[0], 'pkexec');
  assert.equal(command[3], `printf ${raw} > ${file}`);
}
for (const raw of ['', 'intel\t2', 'other\t1', 'cpufreq', 'cpufreq\t1\textra']) {
  assert.equal(boost.parseState(raw).available, false);
}
assert.throws(() => boost.setCommand('other', true), /Unsupported/);
console.log('Passed: Intel and CPUFreq polarity, invalid status, command paths.');
