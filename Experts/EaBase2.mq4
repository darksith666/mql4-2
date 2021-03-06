//+------------------------------------------------------------------+
//|                                      Moving Average_Мodified.mq4 |
//|                      Copyright © 2013, MetaQuotes Software Corp. |
//|                                      Modified by BARS            |
//+------------------------------------------------------------------+
#define MAGICMA  20160917
#define UP "UP"
#define DOWN "DOWN"
#define UP_CROSS "UP_CROSS"
#define DOWN_CROSS "DOWN_CROSS"
//-----------------------------------------
/*
extern int     StopLoss           = 10;
extern int     InitingStopLoss    = 20;
extern int     StopStep           = 4;
extern int     MinProfit          = 5;

extern double  Lots               = 0.1;
extern double  MaximumRisk        = 0.02;
*/

//extern int     StopLoss           = 10;
extern int     InitingStopLoss    = 20;
extern int     StopStep           = 0;
//extern int     MinProfit          = 5;
extern int     ProfitLoss         = 20;
extern double  Lots               = 0.1;
extern double  MaximumRisk        = 0.02;

/*
PERIOD_M1
PERIOD_M5
PERIOD_M15
PERIOD_M30 30
PERIOD_H1 60
PERIOD_H4 240
PERIOD_D1 1440
PERIOD_W1 10080 
PERIOD_MN1 43200
*/
extern int   TimeFrame_Small = PERIOD_M5;//PERIOD_M30;
extern int   TimeFrame_Big = PERIOD_H1;//PERIOD_H4;
extern double  DecreaseFactor     = 3;
extern int     MovingShift        = 1;
extern color   BuyColor           = clrCornflowerBlue;
extern color   SellColor          = clrSalmon;
//---
double SL=0,TP=0;
bool  bNoHandingStop = true;
//-- Include modules --
#include <stderror.mqh>
#include <stdlib.mqh>
#include <CustomFunction.mqh>
//+------------------------------------------------------------------+
int OnInit()
{
   //Print("StopLoss=", StopLoss, " TakeProfit=", TakeProfit, " MovingPeriod_Open=", MovingPeriod_Open, " MovingPeriod_Close=", MovingPeriod_Close);
   return(INIT_SUCCEEDED);
}                                                                
//+------------------------------------------------------------------+
void start()
  {
//--- If there are more than 100 bars in the chart and the trade flow is free
   bool res = IsTradeAllowed();
   if(Bars<100 || res==false)
      return;
   if(CheckNewBar() == false)
      return;
//--- If the calculated lot size is in line with the current deposit amount
   if(CalculateCurrentOrders(Symbol())==0)
      CheckForOpen();   // start working
   else
      CheckForClose();  // otherwise, close positions
  }
//+------------------------------------------------------------------+
//| Determines open positions                                        |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
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
//+------------------------------------------------------------------+
//| Calculates the optimum lot size                                  |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal(); // history orders total
   int    losses=0;              // number of loss orders without a break
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
  
  string GetCurrentDirect()
  {
      string direct = UP;
      double mainValue = iStochastic(NULL,TimeFrame_Big,5,3,3,MODE_SMA,0,MODE_MAIN,MovingShift);
      double signalValue = iStochastic(NULL,TimeFrame_Big,5,3,3,MODE_SMA,0,MODE_SIGNAL,MovingShift);
      if(mainValue < signalValue)
         direct = DOWN;
      return direct;
  }
  string GetTradeSigal()  //获取交易信号
  {
      string direct = "";
      double preMainValue = iStochastic(NULL,TimeFrame_Small,5,3,3,MODE_SMA,0,MODE_MAIN,MovingShift+1);
      double preSignalValue = iStochastic(NULL,TimeFrame_Small,5,3,3,MODE_SMA,0,MODE_SIGNAL,MovingShift+1);
      double mainValue = iStochastic(NULL,TimeFrame_Small,5,3,3,MODE_SMA,0,MODE_MAIN,MovingShift);
      double signalValue = iStochastic(NULL,TimeFrame_Small,5,3,3,MODE_SMA,0,MODE_SIGNAL,MovingShift);
      if(preMainValue <= preSignalValue && mainValue > signalValue)
         direct = UP_CROSS;
      else if(preMainValue >= preSignalValue && mainValue < signalValue)
         direct = DOWN_CROSS;
      return direct;
  }
 
//+------------------------------------------------------------------+
//| Position opening function                                        |
//+------------------------------------------------------------------+
void CheckForOpen()
{
   double ma;
   int    res;

   double  takeProfit = 0;
   //---- buy conditions
   if(GetCurrentDirect() == UP && GetTradeSigal() == UP_CROSS)
   {
         int ticket = OpenBuyOrder(Symbol(), LotsOptimized(), 5, MAGICMA,  "Buy Order");
         AddStopProflt(ticket, GetStopLoss(OP_BUY, InitingStopLoss), GetTakeProfit(OP_BUY, ProfitLoss));
   }
   //---- sell conditions
   if(GetCurrentDirect() == DOWN && GetTradeSigal() == DOWN_CROSS)
   {
         int ticket = OpenSellOrder(Symbol(), LotsOptimized(), 5, MAGICMA,  "Buy Order");
         AddStopProflt(ticket, GetStopLoss(OP_SELL, InitingStopLoss), GetTakeProfit(OP_SELL, ProfitLoss));
   }
   bNoHandingStop = true;
}
//+------------------------------------------------------------------+
//| Position closing function                                        |
//+------------------------------------------------------------------+
void CheckForClose()
{
   double ma;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if(OrderType()==OP_BUY)
      {
         if(GetCurrentDirect() == DOWN )  //|| GetTradeSigal() == DOWN_CROSS
            OrderClose(OrderTicket(), OrderLots(), Bid, 5, BuyColor);
      }
      if(OrderType()==OP_SELL)
      {
          if(GetCurrentDirect() == UP ) //|| GetTradeSigal() == UP_CROSS
             OrderClose(OrderTicket(),OrderLots(),Ask,5,SellColor); 
      }
   }
 //  CheckTrailingStop(Symbol(), StopLoss, MinProfit, MAGICMA);
}

void CheckTrailingStop(string argSymbol, int argTrailingStop, int argMinProfit,
   int argMagicNumber)
{
   for(int Counter = 0; Counter < OrdersTotal(); Counter++)
   {
      OrderSelect(Counter, SELECT_BY_POS);
      if(OrderSymbol() != argSymbol || OrderMagicNumber() != argMagicNumber ) continue;
      if(OrderType() == OP_BUY)
      {
         double MaxStopLoss = MarketInfo(argSymbol, MODE_BID) - (argTrailingStop*PipPoint(argSymbol));
         MaxStopLoss = NormalizeDouble(MaxStopLoss, MarketInfo(argSymbol, MODE_DIGITS));
         double CurrentStop = NormalizeDouble(OrderStopLoss(), MarketInfo(argSymbol, MODE_DIGITS));
         double PipsProfit = MarketInfo(argSymbol, MODE_BID) - OrderOpenPrice();
         double minProfit = argMinProfit*PipPoint(argSymbol);
         if(bNoHandingStop = true)
         {
            if(CurrentStop < MaxStopLoss && PipsProfit >= minProfit)
            {
               bool Trailed = OrderModify(OrderTicket(), OrderOpenPrice(), MaxStopLoss, OrderTakeProfit(), 0);
               bNoHandingStop = false;
               if(Trailed == false)
               {
                  Print("Error CheckTrailingStop \n");
               }
            }
         }
         else 
         {
            if(MaxStopLoss - CurrentStop > StopStep*PipPoint(argSymbol))
            {
               bool Trailed = OrderModify(OrderTicket(), OrderOpenPrice(), MaxStopLoss, OrderTakeProfit(), 0);
               if(Trailed == false)
               {
                  Print("Error CheckTrailingStop \n");
               }
            }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double MaxStopLoss = MarketInfo(argSymbol, MODE_ASK) + (argTrailingStop*PipPoint(argSymbol));
         MaxStopLoss = NormalizeDouble(MaxStopLoss, MarketInfo(argSymbol, MODE_DIGITS));
         double CurrentStop = NormalizeDouble(OrderStopLoss(), MarketInfo(argSymbol, MODE_DIGITS));
         double PipsProfit = OrderOpenPrice() - MarketInfo(argSymbol, MODE_ASK);
         double minProfit = argMinProfit*PipPoint(argSymbol);      
         if(bNoHandingStop = true)
         {
            if(CurrentStop > MaxStopLoss && PipsProfit >= minProfit)
            {
               bool Trailed = OrderModify(OrderTicket(), OrderOpenPrice(), MaxStopLoss, OrderTakeProfit(), 0);
               bNoHandingStop = false;
               if(Trailed == false)
               {
                  Print("Error CheckTrailingStop \n");
               }
            }
         }
         else 
         {
            if(CurrentStop - MaxStopLoss > StopStep*PipPoint(argSymbol))
            {
               bool Trailed = OrderModify(OrderTicket(), OrderOpenPrice(), MaxStopLoss, OrderTakeProfit(), 0);
               if(Trailed == false)
               {
                  Print("Error CheckTrailingStop \n");
               }
            }
         }
      }
   }
}
