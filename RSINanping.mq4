//+------------------------------------------------------------------+
//|                                                   RSINanping.mq4 |
//|                                           Copyright 2020,Jupiter |
//|                                           https://www.nonado.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020,Jupiter"
#property link      "https://www.nonado.com"
#property version   "1.00"
#property strict

input    int      InpRSIPeriod = 14;
input    double   InpStartLot = 0.01;
input    int      InpStep = 300;
input    int      InpProfitPt = 50;
input    int      InpMaxLot = 5;


double   g_avg_price;
double   g_min_price;
double   g_max_price;
double   g_sum_lots;

int      g_position_type;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(OrdersTotal() == 0) {
      CheckOpen();
   } else {
      GetPositionStatus();
      CheckClose();
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckOpen() {
   double rsi = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE, 0);
   if(rsi > 80) {
      // sell
      SendOrder(_Symbol, InpStartLot, false);
   } else if (rsi< 20) {
      // buy
      SendOrder(_Symbol, InpStartLot, true);
   }
}

//+------------------------------------------------------------------+
//| Check additional order condition function                        |
//+------------------------------------------------------------------+
void CheckAdditionalOrder() {
   int order_count = OrdersTotal();
   if(order_count > 0) {
      if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
         string symbol = OrderSymbol();
         double ask = MarketInfo(symbol, MODE_ASK);
         double bid = MarketInfo(symbol, MODE_BID);
         double point = MarketInfo(symbol, MODE_POINT);
         double open_price = OrderOpenPrice();
         if(symbol == _Symbol) {
            double step = InpStep * point;

            if(g_position_type == OP_BUY) {
               if(ask <= g_min_price - step) {
                  int order_times = 1;
                  while(order_times <(InpMaxLot - (g_sum_lots / InpStartLot))) {
                     double predict_avg_price = (g_avg_price *g_sum_lots + ask * order_times*InpStartLot)/ (g_sum_lots + InpStartLot*order_times);
                     if(predict_avg_price < (ask + (g_max_price - ask)/2)  /*&& bid <= g_min_price - step* order_times*/) {
                        SendOrder(symbol, InpStartLot * order_times, true);
                        break;
                     }
                     order_times++;
                  }
               }
            } else if (g_position_type == OP_SELL) {
               if(bid >= g_max_price + step ) {
                  int order_times = 1;
                  while(order_times <(InpMaxLot - (g_sum_lots / InpStartLot))) {
                     double predict_avg_price = (g_avg_price * g_sum_lots + ask * order_times*InpStartLot)/ (g_sum_lots + InpStartLot*order_times);
                     if(predict_avg_price > (bid - (bid - g_min_price)/2) /*&& bid >= g_dMaxPrice + step */) {
                        SendOrder(symbol, InpStartLot * order_times, false);
                        break;
                     }
                     order_times++;
                  }
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
//| Close all existing positions.                                    |
//+------------------------------------------------------------------+
void CloseAllPosition() {
   for(int i=OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         double bid = MarketInfo(_Symbol, MODE_BID);
         double ask = MarketInfo(_Symbol, MODE_ASK);
         if(OrderType() == OP_SELL ) {
            int res = OrderClose(OrderTicket(), OrderLots(), ask,0);
         } else if (OrderType() == OP_BUY) {
            int res = OrderClose(OrderTicket(), OrderLots(), bid,0);
         } else {
            bool result = OrderDelete(OrderTicket());
         }
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckClose() {
   double point = MarketInfo(_Symbol, MODE_POINT);
   if(g_position_type == OP_BUY) {
      if((Bid - g_avg_price) > InpProfitPt * point) {
         CloseAllPosition();
         return;
      }
   } else {
      if((g_avg_price - Ask) > InpProfitPt * point) {
         CloseAllPosition();
         return;
      }
   }

   CheckAdditionalOrder();

}

//+------------------------------------------------------------------+
//| Get position status function                                     |
//+------------------------------------------------------------------+
void GetPositionStatus() {
   int order_count = OrdersTotal();
   g_avg_price = 0;
   g_max_price = 0;
   g_min_price = 0;
   if(order_count > 0) {
      if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
         string symbol = OrderSymbol();
         if(symbol == _Symbol) {
            double open_price = OrderOpenPrice();
            datetime open_time = OrderOpenTime();
            g_position_type = (int)OrderType();
            int min_index  = iBarShift(symbol, PERIOD_CURRENT, open_time);
            datetime first_time  = open_time;
            double sum_price = 0;
            double sum_lots = 0;
            double lots = 0;

            g_max_price = open_price;
            g_min_price = open_price;
            min_index = iBarShift(symbol, PERIOD_CURRENT, open_time);
            int max_index = min_index;

            for(int index = 0; index < order_count; index++) {
               if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES)) {
                  open_price = OrderOpenPrice();
                  lots = OrderLots();
                  open_time = OrderOpenTime();
                  if(g_max_price < open_price) {
                     g_max_price = open_price;
                     max_index = iBarShift(symbol, PERIOD_CURRENT, open_time);
                  }
                  if(g_min_price > open_price) {
                     g_min_price = open_price;
                     min_index = iBarShift(symbol, PERIOD_CURRENT, open_time);
                  }
                  sum_price += open_price * lots;
                  sum_lots += lots;
               }

            }

            g_avg_price = sum_price / sum_lots;
            g_sum_lots = sum_lots;

            if(g_position_type == OP_BUY) {
//               g_dHighestPrice = GetHighestPrice(symbol, g_nMaxIndex, InpWeakBars);
//               g_dLowestPrice = iLow(symbol, PERIOD_CURRENT, iLowest(symbol, PERIOD_CURRENT, MODE_LOW, g_nMaxIndex+1));
//               g_dThreePartWidth = (g_dHighestPrice  - g_dLowestPrice/*g_min_price*/) /3;
//               g_dThreePartPrice = /*g_min_price*/ g_dLowestPrice + g_dThreePartWidth;
            } else if(g_position_type == OP_SELL) {
//               g_dLowestPrice = GetLowestPrice(symbol, g_nMinIndex, InpWeakBars);
//               g_dHighestPrice = iHigh(symbol, PERIOD_CURRENT, iHighest(symbol, PERIOD_CURRENT, MODE_HIGH, g_nMinIndex+1));
//               g_dThreePartWidth =  (g_dHighestPrice/*g_dMaxPrice*/ - g_dLowestPrice ) /3;
//               g_dThreePartPrice = /*g_dMaxPrice */g_dHighestPrice - g_dThreePartWidth;
            }
         }
      }
   }
}


//+------------------------------------------------------------------+
//| Send Order function                                              |
//+------------------------------------------------------------------+
int SendOrder(string symbol, double lot, bool is_buy) {
   bool result = false;
   double bid = MarketInfo(symbol, MODE_BID);
   double ask = MarketInfo(symbol, MODE_ASK);
   if(is_buy)
      return OrderSend(symbol, OP_BUY, lot, ask, 0, 0, 0);
   else
      return OrderSend(symbol, OP_SELL, lot, bid, 0, 0, 0);
   return 0;
}

//+------------------------------------------------------------------+
