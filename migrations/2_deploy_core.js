const DeFIL = artifacts.require("DeFIL");
const EFIL = artifacts.require("EFIL");
const FreeMarket = artifacts.require("FreeMarket");
const NFTMarket = artifacts.require("NFTMarket");
const WhitePaperInterestRateModel = artifacts.require("WhitePaperInterestRateModel");


module.exports = async function(deployer) {

  //布署WhitePaperInterestRateModel
  await deployer.deploy(WhitePaperInterestRateModel,'80000000000000000','1920000000000000000')
  const whitePaperInterestRateModel = await WhitePaperInterestRateModel.deployed()
  
  //布署efil
  await deployer.deploy(EFIL)
  const eFil = await EFIL.deployed()
  

  //布署FreeMarket
  await deployer.deploy(FreeMarket)
  //const freeMarket = await FreeMarket.deployed()

  //布署NFTMarket
  await deployer.deploy(NFTMarket)
  const nftMarket = await NFTMarket.deployed()
  
  
  //布署DeFIL
  //await deployer.deploy(DeFIL)
  await deployer.deploy(DeFIL,whitePaperInterestRateModel.address,nftMarket.address,eFil.address)
  const deFIL = await DeFIL.deployed()
  console.log("deFIL deployed seccuess:",deFIL.address)
  //const deFil = await DeFIL.deployed()
  
  
};
