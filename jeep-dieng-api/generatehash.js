const bcrypt = require('bcryptjs');

async function main() {
  const hash = await bcrypt.hash('Admin@123', 10);
  console.log('\nHash untuk Admin@123:');
  console.log(hash);
  console.log('\nSQL update:');
  console.log(`UPDATE users SET password = '${hash}' WHERE role IN ('admin','supir','pelanggan');`);
}

main();