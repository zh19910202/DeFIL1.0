import React, { Component } from 'react'
import Web3 from 'web3'
import './App.css'

import DeFIL from "../abis/DeFIL.json";
import FreeMarket from "../abis/FreeMarket.json";
import EFIL from "../abis/EFIL.json";
import NFTMarket from "../abis/NFTMarket.json";

class App extends Component {

  async componentWillMount() {
    await this.loadWeb3()
    await this.loadBlockchainData()
  }

  async loadBlockchainData() {
    const web3 = window.web3

    const accounts = await web3.eth.getAccounts()
    this.setState({ account: accounts[0] })

    const networkId = await web3.eth.net.getId()
    this.setState({ networkId: networkId })

    //余额
    let balance = await web3.eth.getBalance(accounts[0])
    balance = Web3.utils.fromWei(balance, 'ether');
    this.setState({ balance: balance })

    //加载实例
    //加载DeFIL

    const DeFilInstance = new web3.eth.Contract(DeFIL.abi,DeFIL.address)
    let cashAmount = await DeFilInstance.methods.getCash().call()
    cashAmount = web3.utils.fromWei(cashAmount,'ether') ;

    let currentBorrowBalance = await DeFilInstance.methods.borrowBalanceStored(accounts[0]).call()
    currentBorrowBalance = web3.utils.fromWei(currentBorrowBalance,'ether')

    let tokenIds = await DeFilInstance.methods.getAccountCollateralsInfo(accounts[0]).call()
    this.setState({DeFilInstance,cashAmount,currentBorrowBalance,tokenIds})
    
    //贷款利率
    let borrowrate = await DeFilInstance.methods.borrowRatePerBlock().call()
    borrowrate = web3.utils.fromWei(web3.utils.toBN(borrowrate * 2102400), 'ether') * 100 ;
    this.setState({borrowrate})
    
    //获取存款利率
    //supplyRatePerBlock
    let supplywrate = await DeFilInstance.methods.supplyRatePerBlock().call()
    supplywrate = web3.utils.fromWei(web3.utils.toBN(supplywrate * 2102400), 'ether') * 100 ;
    this.setState({supplywrate})
    

    //加载FreeMarket
    const FreeMarketInstance = new web3.eth.Contract(FreeMarket.abi,FreeMarket.address)
    
    this.setState({FreeMarketInstance})

    //加载efil

    const EFILInstance = new web3.eth.Contract(EFIL.abi,EFIL.address)
    let EFILbalance = await EFILInstance.methods.balanceOf(accounts[0]).call()
    EFILbalance = web3.utils.fromWei(EFILbalance,'ether')
    this.setState({EFILInstance,EFILbalance})

    //加载nftmarket

    const NFTMarketInstance = new web3.eth.Contract(NFTMarket.abi,NFTMarket.address)
    
    let NFTbalance = await NFTMarketInstance.methods.balanceOf(accounts[0]).call()
    this.setState({NFTMarketInstance,NFTbalance})

  }
  

  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()
    }
    else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider)
    }
    else {
      window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!')
    }
  }

  
  constructor(props) {
    super(props)
    this.changeInput = this.changeInput.bind(this);
    this.state = {
      DeFilInstance : null,
      account:null,
      FreeMarketInstance:null,
      balance:null,
      EFILInstance:null,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
      NFTMarketInstance:null,
      borrowrate:null,
      supplywrate:null,
     
    }
    
  }


  //efil授权至DeFIL
  authEFILToDeFIL = async() =>{
      let amount = this.state.amount
      
      amount = window.web3.utils.toWei(amount,"ether")
   
     this.state.EFILInstance.methods.approve(DeFIL.address,amount).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //efil授权至FreeMarket
  authEFILToFreeMarket = async() =>{
    let amount = this.state.amount
    
    amount = window.web3.utils.toWei(amount,"ether")
   
   this.state.EFILInstance.methods.approve(FreeMarket.address,amount).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
}

  //nft授权至DeFIL
  authNFTToDeFIL = async() =>{
      this.state.NFTMarketInstance.methods.approve(DeFIL.address,this.state.tokenID).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
   
  }


  //nft授权至FreeMarket
  authNFTToFreeMarket = async() =>{
    this.state.NFTMarketInstance.methods.approve(FreeMarket.address,this.state.tokenID).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
 
}




  
  //提交nft铸造请求
  commit = async() =>{

    //this.state.productID,this.state.poolNmae,this.state.power,this.state.pledgeCoinCount,this.state.expiration
    this.state.NFTMarketInstance.methods.commitNFTCreateRequest(this.state.productID,this.state.poolNmae,this.state.power,this.state.pledgeCoinCount,this.state.expiration).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
    

  }

  //查询请求铸造列表

  checkout = async()=>{
    let address = this.state.address
    let lists =  await this.state.NFTMarketInstance.methods.getNFTPendingReq(address).call()
    alert(lists.join('\n'))
  }


  //铸造nft
  mint = async()=>{
    //console.log(this.state.reqID,this.state.owner)
    this.state.NFTMarketInstance.methods.createNFTMachine(this.state.reqID,this.state.owner).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //抵押
  pledge = async() =>{
    //console.log(this.state.tokenID)
    this.state.DeFilInstance.methods.collateralize(this.state.tokenID).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //存款
  mintEFIL = async()=>{
   let userPutAmount = this.state.userPutAmount
   userPutAmount = window.web3.utils.toWei(userPutAmount,"ether")
  
    //console.log(userPutAmount)
    this.state.DeFilInstance.methods.mint(userPutAmount).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //借款
  borrow = async()=>{
    //console.log(this.state.userBorrowAmount)
    let amount = this.state.userBorrowAmount
    amount = window.web3.utils.toWei(amount,"ether")
    this.state.DeFilInstance.methods.borrow(amount).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //还款
  repay = async()=>{
    //console.log(this.state.userRepayBorrowAmount)
    this.state.DeFilInstance.methods.repayBorrow(this.state.userRepayBorrowAmount).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //清算


  //***********************************

  //查看借款信息列表
  checkoutBorrowInfo= async()=>{
    //console.log(this.state.FreeMarketInstance)
    let info = await this.state.FreeMarketInstance.methods.getInfoAll().call()
    alert(info.join('\n'))
  }

  //发布借贷需求
  publishBorrow = async() =>{
    //console.log(this.state.ID,this.state.borrowBalance,this.state.time,this.state.rate)
    let idLists = this.state.ID
    idLists = idLists.split(",")
    let amount = this.state.borrowBalance
    amount = window.web3.utils.toWei(amount,'ether')
    //console.log(idLists,amount)
    this.state.FreeMarketInstance.methods.publicBorrowMessage(idLists,amount,this.state.time,this.state.rate).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
 
   
  }
  //发布放贷需求
  publishLend = async() =>{
    // console.log(this.state.amount,this.state.time,this.state.interset)
    let amount = window.web3.utils.toWei(this.state.amount,'ether')
    this.state.FreeMarketInstance.methods.publicLendMessage(amount,this.state.time,this.state.interset).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //借进
  borrowNew = async() =>{
    console.log(this.state.borrowInfoID)
  }

  //借出
  lendNew = async()=>{
    //console.log(this.state.borrowInfoID)
    this.state.FreeMarketInstance.methods.lend(this.state.borrowInfoID).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }
  //偿还
  repayNew = async()=>{
    //console.log(this.state.borrowInfoID,this.state.amount)
    let amount = window.web3.utils.toWei(this.state.amount,'ether')
    this.state.FreeMarketInstance.methods.repayBorrow(this.state.borrowInfoID,amount).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //清算
  liquidationBorrowNew= async=>{
    //console.log(this.state.borrowInfoID)
    this.state.FreeMarketInstance.methods.liquidationBorrow(this.state.borrowInfoID).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  // 查询借款本息额度
  getBorrowBalance = async() =>{
   let balance =  await this.state.FreeMarketInstance.methods.principalAndInterest(this.state.borrowInfoID).call()
   alert(balance)
  }

 //查询商城所有nft
 getNFTInfoAll = async() =>{
  let info =  await this.state.NFTMarketInstance.methods.getNFTInfoAll().call()
  alert(info.join('\n'))
 }

  //购买NFT
  buyNFT = async() =>{
    //console.log(this.state.tokenID)
    let price = window.web3.utils.toWei(this.state.price)
    //console.log(price,this.state.tokenID)
    this.state.NFTMarketInstance.methods.buyShopNFTMachine(this.state.tokenID,price).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //上架NFT
  upNFT = async() =>{
    //console.log(this.state.tokenID)
    //console.log(price,this.state.tokenID)
    let price = window.web3.utils.toWei(this.state.price)
    this.state.NFTMarketInstance.methods.saleNFTMachine(this.state.tokenID,price).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //下架NFT
  downNFT = async() =>{
    console.log(this.state.tokenID)
    this.state.NFTMarketInstance.methods.productOff(this.state.tokenID).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //修改价格
  setPrice = async() =>{

    console.log(this.state.tokenID,this.state.price)
    let price = window.web3.utils.toWei(this.state.price)
    this.state.NFTMarketInstance.methods.resetNFTPrice(this.state.tokenID,price).send({from:this.state.account}).on('transactionHash',(transactionHash)=>{console.log('transactionHash:',transactionHash)})
  }

  //测试
  test = async=>{
    console.log(this.state.ID)
  }

  //changeInput
  changeInput = async(type,e)=>{
      console.log(e.target.value)
      this.setState({
        [type] : e.target.value
      })
  }

  render() {
    let networkId = this.state.networkId
    if (networkId === 4){
      networkId = "Rinkeby"
    }else{
      networkId = "未知"
    }


    return (
      <div>
       <div>网络：{networkId}</div>
       <div>账户：{this.state.account}</div>
       <div>余额：{this.state.balance} ETH</div>
       <div>借款利率：{this.state.borrowrate}%</div> 
       <div>存款利率：{this.state.supplywrate}%</div> 
       <div>借款池余额:{this.state.cashAmount} EFIL</div>
       <div>EFIL余额：{this.state.EFILbalance}</div>
       <div>欠款：{this.state.currentBorrowBalance}</div>
       <div>已经抵押NFT：{this.state.tokenIds}</div>
       <div>查询NFT数量：{this.state.NFTbalance}</div>
       <div>EFIL授权至DEFIL:<input type="text" placeholder="授权额度" value = {this.state.amount} onChange = {(e) => {this.changeInput('amount',e)}}/><button onClick={()=>{this.authEFILToDeFIL()}}>确定</button></div>
       <div>EFIL授权至FreeMarket:<input type="text" placeholder="授权额度" value = {this.state.amount} onChange = {(e) => {this.changeInput('amount',e)}}/><button onClick={()=>{this.authEFILToFreeMarket()}}>确定</button></div>
       <div>NFT授权至DEFIL:<input type="text" placeholder="tokenID" value = {this.state.tokenID} onChange = {(e) => {this.changeInput('tokenID',e)}}/><button onClick={()=>{this.authNFTToDeFIL()}}>确定</button></div>
       <div>NFT授权至FreeMarket:<input type="text" placeholder="tokenID" value = {this.state.tokenID} onChange = {(e) => {this.changeInput('tokenID',e)}}/><button onClick={()=>{this.authNFTToFreeMarket()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>提交铸造请求:<input type="text" placeholder="productID" value = {this.state.productID} onChange = {(e) => {this.changeInput('productID',e)}}/><input type="text"  placeholder="所属矿池" value = {this.state.poolNmae} onChange = {(e) => {this.changeInput('poolNmae',e)}}/><input type="text"  placeholder="有效算力" value = {this.state.power} onChange = {(e) => {this.changeInput('power',e)}}/><input type="text"  placeholder="质押币数量" value = {this.state.pledgeCoinCount} onChange = {(e) => {this.changeInput('pledgeCoinCount',e)}}/><input type="text"  placeholder="过期时间" value = {this.state.expiration} onChange = {(e) => {this.changeInput('expiration',e)}}/><button onClick={()=>{this.commit()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>查询某个用户铸造列表:<input type="text" placeholder="address" value = {this.state.address} onChange = {(e) => {this.changeInput('address',e)}}/><button onClick={()=>{this.checkout()}}>查询</button></div>
         
       <div>---------------------------------------------------------</div>
       <div>铸造nft:<input type="text" placeholder="请求铸造ID" value = {this.state.reqID} onChange = {(e) => {this.changeInput('reqID',e)}}/><input type="text" placeholder="拥有者" value = {this.state.owner} onChange = {(e) => {this.changeInput('owner',e)}}/><button onClick={()=>{this.mint()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>抵押NFT：<input type="text" placeholder="tokenID" value = {this.state.tokenID} onChange = {(e) => {this.changeInput('tokenID',e)}}/><button onClick={()=>{this.pledge()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>存款:<input type="text"  placeholder="存款金额" value = {this.state.userPutAmount} onChange = {(e) => {this.changeInput('userPutAmount',e)}}/><button onClick={()=>{this.mintEFIL()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>借款:<input type="text"  placeholder="借款金额" value = {this.state.userBorrowAmount} onChange = {(e) => {this.changeInput('userBorrowAmount',e)}}/><button onClick={()=>{this.borrow()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>还款：<input type="text"  placeholder="还款金额" value = {this.state.userRepayBorrowAmount} onChange = {(e) => {this.changeInput('userRepayBorrowAmount',e)}}/><button onClick={()=>{this.repay()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>---------------------------------------------------------</div>
       <h1>点对点借贷市场</h1>
       <div>---------------------------------------------------------</div>
       <div>查询欠款：<input type="text"  placeholder="借款信息ID" value = {this.state.borrowInfoID} onChange = {(e) => {this.changeInput('borrowInfoID',e)}}/><button onClick={()=>{this.getBorrowBalance()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>发布借贷需求：<input type="text" placeholder="tokenId,多个Id使用,分割" value = {this.state.ID} onChange = {(e) => {this.changeInput('ID',e)}}/><input type="text"  placeholder="金额"  value = {this.state.borrowBalance} onChange = {(e) => {this.changeInput('borrowBalance',e)}}/ ><input type="text"  placeholder="周期" value = {this.state.time} onChange = {(e) => {this.changeInput('time',e)}}/><input type="text"  placeholder="利率" value = {this.state.rate} onChange = {(e) => {this.changeInput('rate',e)}}/><button onClick={()=>{this.publishBorrow()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       {/* <div>发布借出需求：<input type="text"  placeholder="金额" value = {this.state.amount} onChange = {(e) => {this.changeInput('amount',e)}}/><input type="text"  placeholder="周期" value = {this.state.time} onChange = {(e) => {this.changeInput('time',e)}}/><input type="text"  placeholder="利率" value = {this.state.interset} onChange = {(e) => {this.changeInput('interset',e)}}/><button onClick={()=>{this.publishLend()}}>确定</button></div>
       <div>---------------------------------------------------------</div> */}
       <div>借款信息列表：<button onClick={()=>{this.checkoutBorrowInfo()}}>查询</button></div>
       <div>---------------------------------------------------------</div>
       {/* <div>借进：<input type="text"  placeholder="借款信息ID" value = {this.state.borrowInfoID} onChange = {(e) => {this.changeInput('borrowInfoID',e)}}/><button onClick={()=>{this.borrowNew()}}>确定</button></div>
       <div>---------------------------------------------------------</div> */}
       <div>借出：<input type="text"  placeholder="借款信息ID" value = {this.state.borrowInfoID} onChange = {(e) => {this.changeInput('borrowInfoID',e)}}/><button onClick={()=>{this.lendNew()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>偿还：<input type="text"  placeholder="借款信息ID" value = {this.state.borrowInfoID} onChange = {(e) => {this.changeInput('borrowInfoID',e)}}/><input type="text"  placeholder="还款金额" value = {this.state.amount} onChange = {(e) => {this.changeInput('amount',e)}}/><button onClick={()=>{this.repayNew()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>清算：<input type="text"  placeholder="借款信息ID" value = {this.state.borrowInfoID} onChange = {(e) => {this.changeInput('borrowInfoID',e)}}/><button onClick={()=>{this.liquidationBorrowNew()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>---------------------------------------------------------</div>
       <div>查询NFT商城列表:<button onClick={()=>{this.getNFTInfoAll()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>购买NFT：<input type="text"  placeholder="tokenID" value = {this.state.tokenID} onChange = {(e) => {this.changeInput('tokenID',e)}}/><input type="text"  placeholder="价格" value = {this.state.price} onChange = {(e) => {this.changeInput('price',e)}}/><button onClick={()=>{this.buyNFT()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>上架NFT:<input type="text"  placeholder="tokenID" value = {this.state.tokenID} onChange = {(e) => {this.changeInput('tokenID',e)}}/><input type="text"  placeholder="价格" value = {this.state.price} onChange = {(e) => {this.changeInput('price',e)}}/><button onClick={()=>{this.upNFT()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>修改价格:<input type="text"  placeholder="tokenID" value = {this.state.tokenID} onChange = {(e) => {this.changeInput('tokenID',e)}}/><input type="text"  placeholder="价格" value = {this.state.price} onChange = {(e) => {this.changeInput('price',e)}}/><button onClick={()=>{this.setPrice()}}>确定</button></div>
       <div>---------------------------------------------------------</div>
       <div>下架NFT:<input type="text"  placeholder="tokenID" value = {this.state.tokenID} onChange = {(e) => {this.changeInput('tokenID',e)}}/><button onClick={()=>{this.downNFT()}}>确定</button></div>
      </div>
    );
  }
}

export default App;