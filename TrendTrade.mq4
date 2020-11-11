//+------------------------------------------------------------------+
//|                                                   TrendTrade.mq4 |
//|                                                     Aoi Morimoto |
//|                                         https://fx-libraries.com/|
//+------------------------------------------------------------------+
#property copyright "Aoi Morimoto"
#property link      "https://fx-libraries.com/"
#property description "Following trend with using ADX"
#property version   "1.01"
#property strict
#define MAGICMA  20200930
//--- Inputs
input double TakeProfit    =300;
input double Lots          =0.1;
input double TrailingStop  =200;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
input int    ADXPeriod     =14;
input double ADXBorder     =25;

//--- TrendDirection indicate the direction of trend
//---  1 -> Up Trend
//--- -1 -> Down Trend
int    TrendDirection=0;
int    OpenOrClose=0;
double plusDI, minusDI;
double ADXValue;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
{
    int buys=0,sells=0;
    //---
    for(int i=OrdersTotal-1;i>=0;i--)
    {
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
        if(OrderSymbol()!=symbol || OrderMagicNumber()==MAGICMA) break;
        
        if(OrderType()==OP_BUY)  buys++;
        if(OrderType()==OP_SELL) sells++;
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
void CheckTrend()
{
    int Updown=0;
    int ADXTrend=0;

    plusDI = iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,0);
    minusDI = iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,0);

    for(int i=0,i<2,i++)
    {
        if(iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,i) >= iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,i)) 
            Updown++;
        else Updown--;
        if(iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,i) > iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,i+1)) 
            ADXTrend++;
        else ADXTrend--;
    }

    if(UpDown>0) TrendDirection=1;
    else if(Updown<0) TrendDirection=-1;
    // TrendDirection:
    // 1  -> Long
    // -1 -> Short

    ADXValue = iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,0);
    if(ADXValue > ADXBorder)
    {
        if(ADXTrend>0) OpenOrClose=1;
        else if(ADXTrend<0) OpenOrClose=-1;
        // OpenOrClose:
        // 1  -> Open
        // -1 -> Close
        // 0  -> retrun false
    }
}
//+------------------------------------------------------------------+
//| Check for turning points                                         |
//+------------------------------------------------------------------+
bool TurningPoint()
{
    if(Bars < n+n1) return
    if(Volume[0]>1) return;

    int n=10;
    int n1=10;

    double highTP0,highTP1;
    double lowTP0,lowTP1;

    string lastTP;
    double reversal_value;
    double tmpHigh=0, tmpLow=0, revHigh=0, revLow=0;

    for(int i=0;i<=n+n1,i++)
    {
        if(High[i]>tmpHigh) tmpHigh = High[i];
        if(Low[i]>tmpLow) tmpLow = Low[i];
        if(i>n1)
        {
            if(High[i]>revHigh) revHigh = High[i];
            if(Low[i]>revLow) revLow = Low[i];
        }
    }
    if(tmpHigh==High[n])
    {
        if(lastTP=="High") highTP0=tmpHigh;
        else if(lastTP=="Low")
        {
            if(tmpHigh>reversal_value)
            {
                highTP1 = highTP0;
                highTP0 = tmpHigh;
            }
        }
        else highTP0=tmpHigh;

        lastTP="High";
        reversal_value=highTP0+(revLow-highTP0)*0.5;
    }
    else if(tmpLow==Low[n])
    {
        if(lastTP=="Low") lowTP0=tmpLow;
        else if(lastTP=="High")
        {
            if(tmpLow<reversal_value)
            {
                lowTP1 = lowTP0;
                lowTP0 = tmpLow;
            }
        }
        else lowTP0=tmpLow;

        lastTP="Low";
        reversal_value=lowTP0+(revHigh-lowTP0)*0.5;

    }
}

//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
    {
        int    res;
        //--- go trading only for first tiks of new bar
        if(Volume[0]>1) return;
        if(OpenOrClose==1)
        {
            //--- sell conditions
            if (TrendDirection==-1)
            {
                res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,Bid-TakeProfit*Point,"TrendTrade",MAGICMA,0,Blue);
            }
            return;
            //--- buy conditions
            if (TrendDirection==1)
            {
                res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,Ask-TakeProfit*Point,"TrendTrade",MAGICMA,0,Red);
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