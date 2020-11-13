//+------------------------------------------------------------------+
//|                                                   TrendTrade.mq4 |
//|                                                     Aoi Morimoto |
//|                                         https://fx-libraries.com/|
//+------------------------------------------------------------------+
#property copyright "Aoi Morimoto"
#property link      "https://fx-libraries.com/"
#property description "Following trend with using ADX"
#property version   "1.00"
#property strict
#define MAGICMA  20200930
//--- Inputs
input double TakeProfit    =300;
input double Lots          =1.0;
input double MaximumRisk   =0.02;
input double MaxDrowdown   =20;
input double DecreaseFactor=3;
input int    ADXPeriod     =14;
input double ADXBorder     =25;

int OpenOrClose=0;
int TrendDirection=0;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
{
    int buys=0,sells=0;
    //---
    for(int i=OrdersTotal()-1;i>=0;i--)
    {
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
        if(OrderSymbol()!=symbol || OrderMagicNumber()!=MAGICMA) continue;
        
        if(OrderType()==OP_BUY)  buys++;
        if(OrderType()==OP_SELL) sells++;
    }
    //--- return orders volume
    if(buys>0) return(buys);
    else       return(sells);
}
//+------------------------------------------------------------------+
//| Calculate stop loss                                              |
//+------------------------------------------------------------------+
double StopLoss(double LotAmount)
{
    double stoploss_d=0;
    stoploss_d = (AccountEquity()*MaxDrowdown/100) / (LotAmount*MarketInfo(Symbol(),MODE_LOTSIZE));
    return stoploss_d;
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
    int    Updown=0;
    int    ADXTrend=0;
    double ADXValue=0;

    OpenOrClose=0;
    TrendDirection=0;

    for(int i=0;i<2;i++)
    {
        if(iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,i) >= iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,i)) 
            Updown++;
        else Updown--;
        if(iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,i) > iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,i+1)) 
            ADXTrend++;
        else ADXTrend--;
    }

    if(Updown>0) TrendDirection=1;
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
void TurningPoint()
{
    if(Volume[0]>1) return;

    int n=10;
    int n1=10;
    
    if(Bars < n+n1) return;

    double highTP0,highTP1;
    double lowTP0,lowTP1;

    string lastTP;
    double reversal_value;
    double tmpHigh=0, tmpLow=0, revHigh=0, revLow=0;

    for(int i=0;i<=n+n1;i++)
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
        //--- buy conditions
        if (TrendDirection==1)
        {
            res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,Ask+TakeProfit*Point,"TrendTrade",MAGICMA,0,Red);
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
    //---
    if(OpenOrClose!=-1) return;

    for(int i=OrdersTotal()-1;i>=0;i--)
    {
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
        if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
        //--- check order type
        if(OrderType()==OP_BUY)
        {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
            Print("OrderClose error ",GetLastError());
        }
        if(OrderType()==OP_SELL)
        {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
            Print("OrderClose error ",GetLastError());
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
    CheckTrend();
    //--- calculate open orders by current symbol
    if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
    else                                    CheckForClose();
    //---
    }
//+------------------------------------------------------------------+