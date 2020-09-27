//+------------------------------------------------------------------+
//|                                                          OCO.mq4 |
//|                                    Copyright © 2007, MQL Service |
//|                                        http://www.mqlservice.com |
/*
    OCO.mq4 is One Cancels the Other script. It should be put in
    MetatradeInstall/experts/scripts folder and after compilation it
    will be available in Navigator/Scripts.
    
    With default parameters it opens two pending stop orders, one for 
    sell and one for buy. This is also known as Straddle and very 
    popular among News Trades. One have a possibility to
    change order type, set Slippage and Expiration. Also
    when StopLoss and/or TakeProfits are set to different value than 0
    this value will be used during sending orders.
    
    One should note, that setting pending orders require that they
    are put in minimum distance from a market price, Ask for BUYSTOP
    and Bid for SELLSTOP. This minimum price is different among
    brokers and can be found in Symbol Properties as Stops level.
    Most of brokers have value 5 which means that a BUYSTOP can be
    put with minimum distance of 6 pips above Ask, and SELLSTOP 6
    pips below Bid. In case that orders are set too close then
    'ERROR #130 : invalid stops' message is put.
    
    MQL Service, 24/01/2007
*/
//| $Id: //mqlservice/mt4files/experts/scripts/OCO.mq4#1 $
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, MQL Service"
#property link      "http://www.mqlservice.com"
#property show_inputs

//---- Parametres Externes
extern double   BuyOrderPrice = 1000.0;
extern double   BuyLots = 1.0;
extern int      BuyStopLoss = 0;
extern int      BuyTakeProfit = 0;
extern int      BuyOrderType = OP_BUYSTOP;
extern double   SellOrderPrice = 0.0;
extern double   SellLots = 1.0;
extern int      SellStopLoss = 0; 
extern int      SellTakeProfit = 0;
extern int      SellOrderType = OP_SELLSTOP;
extern datetime Expiration = D'15/7/2007 12:00';
extern int      Slippage = 1;
extern int      Magic = 20070401;

//---- Section Define
#define LABEL   "OCOLabel"
#define TIMEOUT 3

//---- Variables
double bsl,ssl,btp,stp;
int bt,st;
bool cont = false;
bool flip = true;
int  err1,err;
      
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
   {
//----
      if(BuyStopLoss > 0)
         bsl = BuyOrderPrice - BuyStopLoss*Point;
      else
         bsl = 0.0;
      if(SellStopLoss > 0)
         ssl = SellOrderPrice + SellStopLoss*Point;
      else
         ssl = 0.0;
      if(BuyTakeProfit > 0)
         btp = BuyOrderPrice + BuyTakeProfit*Point;
      else
         btp = 0.0;
      if(SellTakeProfit > 0)
         stp = SellOrderPrice - SellTakeProfit*Point;
      else
         stp = 0.0;
  
      bt = OrderSend(Symbol(), BuyOrderType, BuyLots, BuyOrderPrice, Slippage, bsl, btp, "Buy OCO", Magic, Expiration, Blue);
      if(CheckError()) 
         return(-1);
      st = OrderSend(Symbol(), SellOrderType, SellLots, SellOrderPrice, Slippage, ssl, stp, "Sell OCO", Magic, Expiration, Red);
      if(CheckError())
         {
            RemoveOrder(bt);
            return(-1);
         }
  
      cont = IsTradeAllowed();
      err1 = 0;
      while(cont)
         {
            if(flip) 
               ShowLabel();
            else
               HideLabel();
            flip = !flip;
            err = 0;

            if(OrderSelect(bt, SELECT_BY_TICKET, MODE_TRADES))
               {
                  if(OrderType() <= OP_SELL)
                     {
                        RemoveOrder(st);
                        cont = false;
                     }
               }
            else
               err++;

            if(OrderSelect(st, SELECT_BY_TICKET, MODE_TRADES))
               {
                  if(OrderType() <= OP_SELL)
                     {
                        RemoveOrder(bt);
                        cont = false;
                     }
               }
            else
               err++;
            if(err > 0)
               err1++;
            if(err1 > TIMEOUT) 
               cont = false;
            Sleep(500);
            cont = cont && IsTradeAllowed();
         }
  
      HideLabel();
//----
      return(0);
   }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| script program VOID functions                                    |
//+------------------------------------------------------------------+
#include <stderror.mqh>
#include <stdlib.mqh>

void ShowLabel()
   {
      ObjectCreate(LABEL, OBJ_LABEL, 0, 0, 0);
      ObjectSet(LABEL, OBJPROP_CORNER, 2);
      ObjectSet(LABEL, OBJPROP_XDISTANCE, 4);
      ObjectSet(LABEL, OBJPROP_YDISTANCE, 2);
      ObjectSetText(LABEL, "OCO by http://www.mqlservice.com", 8, "Arial", Yellow);
      WindowRedraw();
   }

void HideLabel()
   {
      ObjectDelete(LABEL);
      WindowRedraw();
   }

bool CheckError()
   {
      int err = GetLastError();
      if(err == ERR_NO_ERROR) return(false);
      Print("ERROR #",err,": ",ErrorDescription(err));
      Alert("ERROR #",err,": ",ErrorDescription(err));
      return(true);
   }

void RemoveOrder(int ticket)
   {
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
         if(OrderType() <= OP_SELL)
            OrderClose(ticket, OrderLots(), OrderClosePrice(), Slippage);
         else
            OrderDelete(ticket);
      CheckError();
   }
//+---- Coded by M. Rutka -------------------------------------------+