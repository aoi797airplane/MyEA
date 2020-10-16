//+------------------------------------------------------------------+
//|                                                  RSIScalping.mq4 |
//|                                                     Aoi Morimoto |
//|                                         https://fx-libraries.com/|
//+------------------------------------------------------------------+
#property copyright "Aoi Morimoto"
#property link      "https://fx-libraries.com/"
#property description "Scalping EA following SMI"
#property version   "1.01"
#property strict
#define MAGICMA  20200930
//--- Inputs
input double TakeProfit     =500;
input double Lots           =0.1;
input double TrailingStop   =200;
input double MaximumRisk    =0.02;
input double DecreaseFactor =3;
input int    SMIPeriod_short=21;
input int    SMIPeriod_long =75;
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
        lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
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
//| Check for trend conditions                                       |
//+------------------------------------------------------------------+
bool CheckTrend()
    {
        int UpDown=0;

        plusDI = iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,0);
        minusDI = iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,0);

        for(int i=0,i<=2,i++)
        {
            if(iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,i) >= 
                iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,i))
                Updown++;
            else Updown--
        }
        if(UpDown>0) TrendDirection=1;
        if(Updown<0) TrendDirection=-1;
        ADXValue = iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,0);
        return true;
    }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
    {
        int    res;
        //--- go trading only for first tiks of new bar
        if(Volume[0]>1) return;
        if(ADXValue>25)
        {
            //--- sell conditions
            if (minusDI>=25)
            {
                res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,Bid-TakeProfit*Point,"MyRSI",MAGICMA,0,Red);
            }
            return;
            //--- buy conditions
            if (plusDI>=25)
            {
                res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,Bid-TakeProfit*Point,"MyRSI",MAGICMA,0,Red);
            }
            return;
        }
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
                if(Bid-OrderOpenPrice()>Ask-Bid && plusDI<25)
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
                if(OrderOpenPrice()-Ask>Ask-Bid && minusDI<25)
                {
                    if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
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
    if(CheckTrend()==false)
        return;
    //--- calculate open orders by current symbol
    if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
    else                                    CheckForClose();
    //---
    }
//+------------------------------------------------------------------+