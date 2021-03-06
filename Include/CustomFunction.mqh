//+------------------------------------------------------------------+
//|                                               CustomFunction.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
#include <stdlib.mqh>
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
//报价点
double PipPoint(string argSymbol)
{
   int Calcdigit = MarketInfo(argSymbol, MODE_DIGITS);
   Print(argSymbol + Calcdigit + "\n");
   double CalcPoint = 0;
   if(Calcdigit == 2 || Calcdigit == 3)
      CalcPoint = 0.01;
   else if(Calcdigit == 4 || Calcdigit == 5)
      CalcPoint = 0.0001;
   return CalcPoint;
}

//滑点和报价点 p17
int GetSlippage(string argSymbol, int SlippagePips)
{
   int CalcDigts = MarketInfo(argSymbol, MODE_DIGITS);
   double CalcSlippage = 0;
   if(CalcDigts == 2 || CalcDigts == 4) 
      CalcSlippage = SlippagePips;
   else if(CalcDigts = 3 || CalcDigts == 5)
      CalcSlippage = SlippagePips*10;
   return CalcSlippage;
}

//设定仓位大小
/*
extern bool DynamicLotSize = true;
extern double EquityPercent = 2;
extern double FixedLotSize = 0.1
extern double StopLoss = 50;
*/
double CalcLotSize(bool argDynamicLotSize, double argEquityPercent, 
 double argStopLoss, double argFixedLotSize)
{
   double LotSize = 0;
   if(argDynamicLotSize == true)
   {
      double RiskAmount = AccountEquity()*(argEquityPercent/100);
      double TickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
      if(Point == 0.01 || Point == 0.00001) TickValue *= 10;
      LotSize = (RiskAmount/argStopLoss)/TickValue;
   }
   else LotSize = argFixedLotSize;
   return LotSize;
}

//仓位验证功能
double VerifyLotSize(string argSymbol, double argLotsize)
{
   if(argLotsize < MarketInfo(argSymbol, MODE_MINLOT))
      argLotsize = MarketInfo(argSymbol, MODE_MINLOT);
    else if(argLotsize > MarketInfo(argSymbol, MODE_MAXLOT))
      argLotsize = MarketInfo(argSymbol, MODE_MAXLOT);
    if(MarketInfo(argSymbol, MODE_LOTSTEP) == 0.1)
      argLotsize = NormalizeDouble(argLotsize, 1);
     else 
      argLotsize = NormalizeDouble(argLotsize, 2);
     return argLotsize;
}

//下单功能
int OpenBuyOrder(string argSymbol, double argLotSize, double argSlippage, 
   double argMagicNumber, string argComment = "Buy Order")
{
   while(IsTradeContextBusy()) Sleep(10);
   
   int Ticket = OrderSend(argSymbol, OP_BUY, argLotSize, MarketInfo(argSymbol, MODE_ASK),
      argSlippage, 0, 0, argComment, argMagicNumber, 0, Green);
   //Error Handling
   if(Ticket == -1)
   {
      int ErrorCode = GetLastError();
      string ErrDesc = ErrorDescription(ErrorCode);
      string ErrAlter = StringConcatenate("Open Buy Order ---- Error ", ErrorCode, ":", ErrDesc);
      Alert(ErrAlter);
      
      string ErrLog = StringConcatenate("Bid:", MarketInfo(argSymbol, MODE_BID), "Ask:", 
         MarketInfo(argSymbol, MODE_ASK), "Lots:", argLotSize);
      Print(ErrLog);
   }
   return Ticket;
}
//下单功能
int OpenSellOrder(string argSymbol, double argLotSize, double argSlippage, 
   double argMagicNumber, string argComment = "Buy Order")
{
   while(IsTradeContextBusy()) Sleep(10);
   
   int Ticket = OrderSend(argSymbol, OP_SELL, argLotSize, MarketInfo(argSymbol, MODE_BID),
      argSlippage, 0, 0, argComment, argMagicNumber, 0, Red);
   //Error Handling
   if(Ticket == -1)
   {
      int ErrorCode = GetLastError();
      string ErrDesc = ErrorDescription(ErrorCode);
      string ErrAlter = StringConcatenate("Open Sell Order ---- Error ", ErrorCode, ":", ErrDesc);
      Alert(ErrAlter);
      
      string ErrLog = StringConcatenate("Bid:", MarketInfo(argSymbol, MODE_BID), "Ask:", 
         MarketInfo(argSymbol, MODE_ASK), "Lots:", argLotSize);
      Print(ErrLog);
   }
   return Ticket;
}

//设定挂单
/*
int OpenBuyStopOrder(string argSymbol, double argLotsize, double argPendingPrice,
double argStopLoss, double argTakeProfit, double argSlippage, double argMagicNumber, 
datetime argExpiration = 0, string argComment = "Buy Stop Order")
{
   while(IsTradeContextBusy()) Sleep(10);
   
   int Ticket = OrderSend(argSymbol, OP_BUYSTOP);
}*/

//平仓功能
bool CloseBuyOrder(string argSymbol, int argCloseTicket, double argSlippage)
{
   OrderSelect(argCloseTicket, SELECT_BY_TICKET);
   if(OrderCloseTime() == 0)
   {
      double CloseLots = OrderLots();
      while(IsTradeContextBusy()) Sleep(10);
      double ClosePrice = MarketInfo(argSymbol, MODE_ASK);
      bool Closed = OrderClose(argCloseTicket, CloseLots, ClosePrice, argSlippage, Red);
      if(Closed == false)
      {
         Print("Error\n");
      }
   }
   return true;
}

//停损与获利计算功能
double CalcBuyStopLoss(string argSymbol, int argStopLoss, double argOpenPrice)
{
   if(argStopLoss == 0) return 0;
   double BuyStopLoss = argOpenPrice-(argStopLoss*PipPoint(argSymbol));
   return BuyStopLoss;
}
double CalcBuyTakeProfit(string argSymbol, int argTakeProfit, double argOpenPrice)
{
   if(argTakeProfit == 0) return 0;
   return (argOpenPrice+(argTakeProfit*PipPoint(argSymbol)));
}

//p67
//设置停损与获利
bool AddStopProflt(int argTicket, double argStopLoss, double argTakeProfit)
{
   if(argStopLoss == 0 && argTakeProfit == 0) return false;
   
   OrderSelect(argTicket, SELECT_BY_TICKET);
//   double OpenPrice = OrderOpenPrice();
   while(IsTradeContextBusy()) Sleep(10);
   
   bool TickMod = OrderModify(argTicket, OrderOpenPrice(), argStopLoss, argTakeProfit, 0);
   if(TickMod == false)
   {
      Print("Error AddStopProflt \n");
   }
   return true;
}

//未平仓单数量
int TotalOrderCount(string argSymbol, int argMagicNumber)
{
   int OrderCount = 0;
   for(int Counter = 0; Counter < OrdersTotal(); Counter++)
   {
      OrderSelect(Counter, SELECT_BY_POS);
      if(OrderMagicNumber() == argMagicNumber && OrderSymbol() == argSymbol)
         OrderCount++;
   }
   return OrderCount;
}
//未平仓买单
int BuyMarketCount(string argSymbol, int argMagicNumber)
{
   int OrderCount;
   for(int Counter = 0; Counter < OrdersTotal(); Counter++)
   {
      OrderSelect(Counter, SELECT_BY_POS);
      if(OrderMagicNumber() == argMagicNumber && OrderSymbol() == argSymbol 
         && OrderType() == OP_BUY)
         OrderCount++;
   }
   return OrderCount;
}
//等待
void WaitToNoBusy()
{
   while(IsTradeContextBusy()) Sleep(10);
}
//多张交易单平仓  p80
void CloseAllBuyOrders(string argSymbol, int argMagicNumber, int argSlippage)
{
   for(int Counter = 0; Counter < OrdersTotal(); Counter++)
   {
      OrderSelect(Counter, SELECT_BY_POS);
      if(OrderMagicNumber() == argMagicNumber && OrderSymbol() == argSymbol 
         && OrderType() == OP_BUY)
      {
         int CloseTicket = OrderTicket();
         double CloseLots = OrderLots();
         WaitToNoBusy();
         double ClosePrice = MarketInfo(argSymbol, MODE_BID);
         bool Closed = OrderClose(CloseTicket, CloseLots, ClosePrice, argSlippage, Red);
         if(Closed == false)
         {
            Print("Error CloseAllBuyOrders \n");
         }
         else Counter--;
      }
   }
}
//平仓多张挂单  p81
void CloseAllBuyStopOrders(string argSymbol, int argMagicNumber, int argSlippage)
{
   for(int Counter=0; Counter < OrdersTotal(); Counter++)
   {
      OrderSelect(Counter, SELECT_BY_POS);
      if(OrderMagicNumber() == argMagicNumber && OrderSymbol() == argSymbol 
         && OrderType() == OP_BUYSTOP)
      {
         int CloseTicket = OrderTicket();
         WaitToNoBusy();
         bool Closed = OrderDelete(CloseTicket, Red);
         if(Closed == false)
         {
            Print("Error CloseAllBuyStopOrders \n");
         }
         else 
            Counter--;
      }
   }
}
//最低获利 P86
extern int TrailingStop = 50;
extern int MinimumProfit = 50;
void BuyTrailingStop(string argSymbol, int argTrailingStop, int argMinProfit,
   int argMagicNumber)
{
   for(int Counter = 0; Counter < OrdersTotal(); Counter++)
   {
      OrderSelect(Counter, SELECT_BY_POS);
      if(OrderSymbol() != argSymbol || OrderMagicNumber() != argMagicNumber || OrderType() != OP_BUY) continue;
      double MaxStopLoss = MarketInfo(argSymbol, MODE_BID) - (argTrailingStop*PipPoint(argSymbol));
      MaxStopLoss = NormalizeDouble(MaxStopLoss, MarketInfo(argSymbol, MODE_DIGITS));
      double CurrentStop = NormalizeDouble(OrderStopLoss(), MarketInfo(argSymbol, MODE_DIGITS));
      double PipsProfit = MarketInfo(argSymbol, MODE_BID) - OrderOpenPrice();
      double MinProfit = argMinProfit*PipPoint(argSymbol);
      if(CurrentStop < MaxStopLoss && PipsProfit >= MinProfit)
      {
         bool Trailed = OrderModify(OrderTicket(), OrderOpenPrice(), MaxStopLoss, OrderTakeProfit(), 0);
         if(Trailed == false)
         {
             Print("Error BuyTrailingStop \n");
         }
      }
   }
}
void SellTrailingStop(string argSymbol, int argTrailingStop, int argMinProfit,
   int argMagicNumber)
{
   for(int Counter = 0; Counter < OrdersTotal(); Counter++)
   {
      OrderSelect(Counter, SELECT_BY_POS);
      if(OrderSymbol() != argSymbol || OrderMagicNumber() != argMagicNumber || OrderType() != OP_BUY) continue;
      double MaxStopLoss = MarketInfo(argSymbol, MODE_ASK) + (argTrailingStop*PipPoint(argSymbol));
      MaxStopLoss = NormalizeDouble(MaxStopLoss, MarketInfo(argSymbol, MODE_DIGITS));
      double CurrentStop = NormalizeDouble(OrderStopLoss(), MarketInfo(argSymbol, MODE_DIGITS));
      double PipsProfit = OrderOpenPrice() - MarketInfo(argSymbol, MODE_ASK);
      double MinProfit = argMinProfit*PipPoint(argSymbol);
      if(CurrentStop > MaxStopLoss && PipsProfit >= MinProfit)
      {
         bool Trailed = OrderModify(OrderTicket(), OrderOpenPrice(), MaxStopLoss, OrderTakeProfit(), 0);
         if(Trailed == false)
         {
             Print("Error BuyTrailingStop \n");
         }
      }
   }
}
/*
//K棒开启的执行
*/ //p120
bool CheckNewBar()
{
   static datetime CurrentTimeStamp = 0;
   bool NewBar = false;
   
   if(CurrentTimeStamp != Time[0])
   {
      CurrentTimeStamp = Time[0];
      NewBar = true;
   }
   return NewBar;
}

/*
//错误重试
int Ticket = 0;
int MaxRetries = 5;
int Retries = 0;
while(Ticket <= 0)
{
   Ticket = OlderSend(Symbol(), OP_BUY, LotSize, OpenPrice, UseSlippage, BuyStopLoss, BuyTakeprofit);
   if(Retries <= MaxRetries) Retries++;
   else break;
}
*/

//保证金检视
/*
extern int MinimumEquity = 8000;

if(AccountEquity() > MinimumEquity)
{
}
else if(AccountEquity <= MinimumEquity)
{
   Alter("111");
}
*/

/*
//检查订单获利情况 p141
OrderSelect(Ticket, SELECT_BY_TICKET);
double GetProfit = 0;
if(OrderType() == OP_BUY)
   GetProfit = OrderClosePrice() - OrderOpenPrice();
else if(OrderType() == OP_SELL) GetProfit = OrderOpenPrice() - OrderClosePrice();
GetProfit /= PipPoint(Symbol()); 
*/

/*
//加倍赌注

*/
//获取当前的Stoploss值。
double GetStopLoss(int l_ordertype, int stopLoss)
 {
    double  stoplossValue = 0;
    if(stopLoss == 0) return 0;
    if(l_ordertype == OP_SELL)
         stoplossValue = MarketInfo(Symbol(), MODE_ASK)+stopLoss*PipPoint(Symbol());
    else if(l_ordertype == OP_BUY) 
      stoplossValue = MarketInfo(Symbol(), MODE_BID)-stopLoss*PipPoint(Symbol());
    return stoplossValue;
 }
 //获取当前的takeProfit值。
 double GetTakeProfit(int l_ordertype, int takeProfit)
 {
    double  takeProfitValue = 0;
    if(takeProfit == 0) return 0;
    if(l_ordertype == OP_SELL)
         takeProfitValue = MarketInfo(Symbol(), MODE_ASK)-takeProfit*PipPoint(Symbol());
    else  takeProfitValue = MarketInfo(Symbol(), MODE_BID)+takeProfit*PipPoint(Symbol());
    return takeProfitValue;
 }
 void log_out(string logString)
 {
   static int filehandle = NULL;
   if(filehandle == NULL || filehandle==INVALID_HANDLE)
   {
      string filename="log.txt";
      filehandle=FileOpen(filename,FILE_WRITE|FILE_CSV);
      if(filehandle<0)
      {
         Print("Failed to open the file by the absolute path ");
         Print("Error code ",GetLastError());
      }
   }
   if(filehandle!=INVALID_HANDLE)
   {
       FileWrite(filehandle,TimeCurrent(),Symbol(), EnumToString(ENUM_TIMEFRAMES(_Period)), logString);
   }
 }
 template<typename T>
 void log_out(string logString, T a)
 {
   static int filehandle = NULL;
   if(filehandle == NULL || filehandle==INVALID_HANDLE)
   {
      string filename=StringFormat("%d.txt", sizeof(T));
      filehandle=FileOpen(filename,FILE_WRITE|FILE_CSV);
      if(filehandle<0)
      {
         Print("Failed to open the file by the absolute path ");
         Print("Error code ",GetLastError());
      }
   }
   if(filehandle!=INVALID_HANDLE)
   {
       FileWrite(filehandle,TimeCurrent(),Symbol(), EnumToString(ENUM_TIMEFRAMES(_Period)), logString);
   }
 }
 
 double LotsOptimized()
 {
   double lot  =  0.1;
   int    orders  = HistoryTotal(); // history orders total
   int    losses  =  0;              // number of loss orders without a break
   //double  Lots   = 0.1;
   double  MaximumRisk  = 0.02;
//---- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//---- calcuulate number of loss orders without a break
   if(DecreaseFactor>0)
   {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //----
         if(OrderProfit()>0)
            break;
         if(OrderProfit()<0)
            losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
   }
//---- return lot size
   if(lot<0.1)
      lot=0.1;
   return(lot);
  }
//计算已打开订单数
int CalculateOpenedOrdersNum(string symbol)
{
   int buys=0,sells=0;
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY) buys++;
         if(OrderType()==OP_SELL) sells++;
        }
   }
//---- return orders volume
   if(buys>0)
      return(buys);
   else
      return(-sells);
}