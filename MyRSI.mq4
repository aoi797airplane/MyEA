//+------------------------------------------------------------------+
//|                                                        MyRSI.mq4 |
//|                                                     Aoi Morimoto |
//|                                         https://fx-libraries.com/|
//+------------------------------------------------------------------+
#include <stdlib.mqh>
#property copyright "Aoi Morimoto, Koh Ikeuchi"
#property link      "https://fx-libraries.com/"
#property description "Relative Strength Index Expert Advisor"
#property version   "1.01"
#property strict
#define MAGICMA  20200919
//--- Inputs
input double TakeProfit    =500;
input double Lots          =0.1;
input double MinimumLots   =0.01;
input double TrailingStop  =200;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
input int    GPeriod       =14;
input double LossCutPoint  =0.04;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=OrdersHistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   //---
   
//--- calculate number of losses orders without a break
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
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
   {
    int    res;
    int WaitingTime = 10;
    int starttime = GetTickCount();
//--- go trading only for first tiks of new bar
    if(Volume[0]>1) return;
    
    //エラーが出ないように変える必要あり
//--- sell conditions
     
     
while(true)
{
   if(GetTickCount() - starttime > WaitingTime*1000)
   {
      Alert("ordersend timeout. check the experts log");
     
   }
   if(IsTradeAllowed()== true)
   {
      RefreshRates();
      if(iRSI(NULL,0,GPeriod,PRICE_MEDIAN,1)>70)
      {
        if (iRSI(NULL,0,GPeriod,PRICE_MEDIAN,0)<=70)
        {   
            res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,Bid-TakeProfit*Point,"MyRSI",MAGICMA,0,Red);
        }
        return;
      }
      if(res != -1){
      break;
      }
      int err = GetLastError();
      Print("[OrderSendError] : " , err , " ", ErrorDescription(err));
   }
   Sleep(100);
}
     
   
//--- buy conditions
while(true)
{
   if(GetTickCount() - starttime > WaitingTime*1000)
   {
      Alert("ordersend timeout. check the experts log");
     
   }
   if(IsTradeAllowed()== true)
   {
    RefreshRates();
    if(iRSI(NULL,0,GPeriod,PRICE_MEDIAN,1)<30)
    {
        if(iRSI(NULL,0,GPeriod,PRICE_MEDIAN,0)>=30)
        {
         res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,Ask+TakeProfit*Point,"MyRSI",MAGICMA,0,Blue);
        }
        return;
    }
      if(res != -1){
      break;
      }
      int err = GetLastError();
      Print("[OrderSendError] : " , err , " ", ErrorDescription(err));
   }
   Sleep(100);
}

//---
}
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
   //エラーが出ないように変える必要あり
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type
      if(OrderType()==OP_BUY)
        {
         if(Bid-OrderOpenPrice()>Ask-Bid && iRSI(NULL,0,GPeriod,PRICE_MEDIAN,0)>70)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         if(MathAbs(Bid-OrderOpenPrice())>OrderOpenPrice()*LossCutPoint)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         if(TrailingStop>0)
           {
            if(Bid-OrderOpenPrice()>Point*TrailingStop)
              {
               if(OrderStopLoss()<Bid-Point*TrailingStop)
                 {
                  //--- modify order and exit
                  if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green))
                     Print("OrderModify error ",GetLastError());
                  return;
                 }
              }
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(OrderOpenPrice()-Ask>Ask-Bid && iRSI(NULL,0,GPeriod,PRICE_MEDIAN,0)<30)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         if(MathAbs(OrderOpenPrice()-Ask)>OrderOpenPrice()*LossCutPoint)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         if(TrailingStop>0)
           {
            if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
              {
               if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                 {
                  //--- modify order and exit
                  if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red))
                     Print("OrderModify error ",GetLastError());
                  return;
                 }
              }
           }
         break;
        }
     }
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//---
  }
//+------------------------------------------------------------------+