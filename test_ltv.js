const amtToInvest = 100;

for (let i = 1; i <= 100; i++) {
  const LTV = i;
  const gpSum = (amtToInvest * 100) / (100 - LTV) - 100;
  const percentOfLoan = (gpSum * 100) / (amtToInvest + gpSum);
  console.log(`LTV: ${LTV}% gpSum: ${gpSum} PercentOfLoan: ${percentOfLoan}`);
}
