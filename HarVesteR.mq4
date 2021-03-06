#property copyright "FORTRADER.RU"
#property link      "http://FORTRADER.RU"
#define MAGICMA  20201015

/*
ﾏ鮏硼鮱 ⅰ頌瑙韃 ・・魵 粢韭・蒡濵 ・濵・ 跿琿・ⅳ 26 ﾌ・ 2008, 
・裝・趺湜 ・ⅳ鍄糺 ・ 碯蒟・蕘 粨蒟 ・浯・・・・・ letters@fortrader.ru
http://www.fortrader.ru/arhiv.php
A detailed description of the parameters adviser available issue of the journal dated May 26 2008, 
suggestions and feedback we will be glad to see in our e-mail: letters@fortrader.ru
http://www.fortrader.ru/arhiv.php
*/




extern string x="ﾍ瑰鵫・ MACD:";
extern int FastEMA = 12;
extern int SlowEMA = 24;
 int SignalEMA = 9;
extern int predel = 6;
extern string x1="ﾍ瑰鵫・ MA:";
extern int SMA1 = 50;
extern int SMA2 = 100;
extern int otstup = 10; 
extern string x2="ﾇ浯湜・矜・蓁 褪・ﾑ・ﾋⅲ・:";
extern int stoplossbars = 6;
extern string x3="ﾊ・頽韃炅 蓁 褪・・ⅵ頸 魵・ ・鈞・靑・ ・・粨燾 ・鉅・";
extern int pprofitum = 2;
extern string x4="・ ・ ADX:";
extern int enable = 0;
extern int periodADX = 14;
extern double Max_Trade_Leverage = 15;
extern double Min_Trade_Leverage = 5;



datetime Bar;int buy,sell,i,a,b;double stoploss,setup2,adx,okbuy,oksell;


double LeverageLotSizing()
   {
      double trade_lots;

      double trade_profit=0;
      double leverage_decrease=0;
      double Trade_Leverage=Max_Trade_Leverage;


      for(int i=0;i<OrdersHistoryTotal();i++)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
               {
                  Print("Error in history!");
                  break;
               }
            if(OrderMagicNumber() != MAGICMA || OrderSymbol() != Symbol()) 
               continue;
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
               {
                  trade_profit = trade_profit+OrderProfit()+OrderSwap()+OrderCommission();
               }
         }
         
      if(trade_profit>0)
         {
            double growth_rate = AccountEquity() / (AccountEquity()-trade_profit); //資産上昇率
            Trade_Leverage = ((Max_Trade_Leverage-Min_Trade_Leverage) / growth_rate) + Min_Trade_Leverage;
         }

      trade_lots = (AccountEquity()* Trade_Leverage)/(MarketInfo(Symbol(), MODE_MARGINREQUIRED)*AccountLeverage());

      if(MarketInfo(Symbol(), MODE_LOTSTEP) == 0.1)
         {
            trade_lots = NormalizeDouble(trade_lots, 1);
         }
   
      else if(MarketInfo(Symbol(), MODE_LOTSTEP)== 0.01)
         {
            trade_lots = NormalizeDouble(trade_lots,2);
         }
         
      if(trade_lots<= MarketInfo(Symbol(), MODE_MINLOT))
         {
            trade_lots = MarketInfo(Symbol(), MODE_MINLOT);
         }
         
      else if(trade_lots >= MarketInfo(Symbol(), MODE_MAXLOT))
         {
            trade_lots = MarketInfo(Symbol(), MODE_MAXLOT);
         }
         
      return(trade_lots);
  }





int start()
  {

     buy=0;sell=0;
     for(  i=0;i<OrdersTotal();i++)
         {
           OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
           if(OrderType()==OP_BUY){buy=1;}
           if(OrderType()==OP_SELL){sell=1;}
         }   
   
   //鈞胙瑯・竟蒻・
   double macd =iMACD(NULL,0,FastEMA,SlowEMA,SignalEMA,PRICE_CLOSE,MODE_MAIN,1);
   double sma1 =iMA(NULL,0,SMA1,0,MODE_SMA,PRICE_CLOSE,1);
   double sma2 =iMA(NULL,0,SMA2,0,MODE_SMA,PRICE_CLOSE,1);
   
   if(Close[1]<sma2){okbuy=1;}
    if(Close[1]>sma2){oksell=1;}
    
   if(enable==1)
   {
   adx=iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,0);
   }else{adx=60;}
   
   

  
  if(Close[1]+otstup*Point>sma1 && Close[1]+otstup*Point>sma2 && macd>0 && buy==0)
  {
  
      buy=0;
      for( i=predel;i>0;i--)
      {
      macd=iMACD(NULL,0,FastEMA,SlowEMA,SignalEMA,PRICE_CLOSE,MODE_MAIN,i);
      if(macd<0){buy=2;}
      }
   
      if(buy==2 && adx>50 && okbuy==1)
      {okbuy=0;
          double stoploss=Low[iLowest(NULL,0,MODE_LOW,stoplossbars,1)];
          OrderSend(Symbol(),OP_BUY,LeverageLotSizing(),Ask,3,stoploss,0,0,MAGICMA,0,Green);
          a=0;
       }
   }
   
   if(Close[1]-otstup*Point<sma1 && Close[1]-otstup*Point<sma2 && macd<0 && sell==0)
  {
  
      sell=0;
      for( i=predel;i>0;i--)
      {
      macd=iMACD(NULL,0,FastEMA,SlowEMA,SignalEMA,PRICE_CLOSE,MODE_MAIN,i);
      if(macd>0){sell=2;}
      }
   
      if(sell==2 && adx>50 && oksell==1)
      {oksell=0;
        
           stoploss=High[iHighest(NULL,0,MODE_HIGH,stoplossbars,1)];
          OrderSend(Symbol(),OP_SELL,LeverageLotSizing(),Bid,3,stoploss,0,0,MAGICMA,0,White);
          b=0;
       }
   }
   
   
   if(buy==2 || buy==1)
   {
    for( i=0;i<OrdersTotal();i++)
         {
           OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
          
           
           if(OrderType()==OP_BUY )
           {  
           double setup2=OrderOpenPrice()+((OrderOpenPrice()-OrderStopLoss())*pprofitum);

            if(Close[1]>setup2 && a==0)
            {
             OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,White);
              OrderClose(OrderTicket(),OrderLots()/2,Bid,3,Violet); 
             
              a=1;
            }
            
            if(a==1 && sma1> Close[1]-otstup*Point)
            {
            OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); 
            }
            
           
           }
      }  
        
  }    
  
           if(sell==2 || sell==1)
   {
    for( i=0;i<OrdersTotal();i++)
         {
           OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
           
           
           if(OrderType()==OP_SELL )
           {  
            setup2=OrderOpenPrice()-((OrderStopLoss()-OrderOpenPrice())*pprofitum);

            if(Close[1]<setup2 && b==0)
            {
             OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,White);
              OrderClose(OrderTicket(),OrderLots()/2,Ask,3,Violet); 
              b=1;
            }
            
            if(b==1 && Close[1]-otstup*Point> sma1)
            {
            OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); 
            
            }
            
           
           }
      } 
      }
  
    
   
   
   

   return(0);
  }