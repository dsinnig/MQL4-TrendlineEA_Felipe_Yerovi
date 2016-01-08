//+------------------------------------------------------------------+
//|                                          Felipe Trendline EA.mq4 |
//|                                       Copyright 2015, Wes Walton |
//|                                                                  |
//|                                                                  |
//|                                    Version 1.2 by Daniel Sinnig  |
//|                                        - Lotsize calculation     |
//|                                    Version 1.3 by Daniel Sinnig  |
//|                                        - Offset for trade entry  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Wes Walton"
#property link      ""
#property version   "1.3"
#property strict

extern int Slippage=5;
extern int Max_Spread_Pips=5;
input double Balance_Risk_In_Percent = 1.0; //Risk relative to account balance in percent. 
input double Lots = 0; //Lot size. If 0 then lot size is calculated from risk level. 
input double Offset = 0.00050; //Offset in trade direction for entry level
extern string Buy_Or_Sell="Buy";

extern int Profit_In_Pips=30;
extern int Stop_Loss_In_Pips=20;

extern int Move_Stop_At_Pips = 20;
extern int Move_Stop_To_Pips = 20;

extern bool Mail_Alert = false;
extern bool PopUp_Alert = false;
extern bool Sound_Alert = false;
extern bool SmartPhone_Notifications=false;

double UsePoint=Digits();
int UseSlippage=Slippage;

bool PlaceStops=false;

datetime TheTime;

bool BuysNotAllowed=false;
bool SellsNotAllowed=false;

int TheBox=9999;

double Price_Level_1;
bool RunEA=true;

int Tickets[1];

bool DrawLine=true;
bool BreakEven=true;
int Magic;

double lotSize; 

int OnInit()
{
   Magic = 456565;

   if(Digits()==2 || Digits()==3) UsePoint=0.01;
   if(Digits()==4 || Digits()==5) UsePoint=0.0001;
   
   if(Digits()==3 || Digits()==5) UseSlippage=Slippage*10;
   
   if (Lots == 0) lotSize = getLotSize(AccountBalance() * Balance_Risk_In_Percent / 100, Stop_Loss_In_Pips*10);
   else lotSize = Lots;
   
   if (lotSize > MarketInfo(Symbol(), MODE_MAXLOT) || lotSize < MarketInfo(Symbol(), MODE_MINLOT)) {
      Print ("Invalid position size");
      ExpertRemove();
   }

   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   ObjectDelete("Trendline Bot Line");
}
void OnTick()
{
   if(BreakEven)
   {
      if(DrawLine) TrendLine();
      if(TheBox==1) CheckTrendLine();
      CheckProfit();
   }
}

double getPipValue() {
   double adjustmentFactor = Point;
   if (Digits == 2 || Digits == 1)
      adjustmentFactor = Point / 10;;
   return (MarketInfo(Symbol(), MODE_TICKVALUE) * adjustmentFactor) / MarketInfo(Symbol(), MODE_TICKSIZE);
}

int getNumberOfDecimals(double lotStep) {
   if (lotStep == 1) return 0; else 
   if (lotStep == 0.1) return 1; else
   if (lotStep == 0.01) return 2; else
   return 3;
}


double getLotSize(double riskCapital, int riskPips) {
   double pipValue = getPipValue();
   double lotStep = MarketInfo(Symbol(),MODE_LOTSTEP);
   double ltSize = NormalizeDouble(riskCapital / ((double) riskPips * pipValue), getNumberOfDecimals(lotStep));  
   return ltSize;
}

void CheckTrendLine()
{
   Price_Level_1 = NormalizeDouble(ObjectGetValueByShift("Trendline Bot Line",0),Digits());

   if(Buy_Or_Sell=="Buy" && Bid>=Price_Level_1+Offset) {TheBox=9999;OpenTrade();return;}
   if(Buy_Or_Sell=="Sell" && Ask<=Price_Level_1-Offset) {TheBox=9999;OpenTrade();return;}
   
return;
}
void TrendLine()
{
   if(ObjectCreate(0,"Trendline Bot Line",OBJ_TREND,0,Time[10],High[10],Time[5],High[5]))
   {
      if (!IsTesting()) TheBox=MessageBox("!!Place trendline and press OK when ready or Cancel to abort. \n\n The position size is " + lotSize + " lots.","Trendline Placement",MB_OKCANCEL);
      else TheBox = 1;
   }
   DrawLine=false;
return;
}
void CheckProfit()
{
   if(OrderSelect(Tickets[0],SELECT_BY_TICKET))
   {
      if(PlaceStops)
      {
         if(Buy_Or_Sell=="Buy") bool m1 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(Stop_Loss_In_Pips*UsePoint),OrderOpenPrice()+(Profit_In_Pips*UsePoint),0,Green); 
         if(Buy_Or_Sell=="Sell") bool m2 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(Stop_Loss_In_Pips*UsePoint),OrderOpenPrice()-(Profit_In_Pips*UsePoint),0,Red); 
      }
      
      if(BreakEven && ((Buy_Or_Sell=="Buy" && Bid>=OrderOpenPrice()+(Move_Stop_At_Pips*UsePoint)) || (Buy_Or_Sell=="Sell" && Ask<=OrderOpenPrice()-(Move_Stop_At_Pips*UsePoint)))) 
      {
         Print("Trendline Move Stop Begin");
         BreakEven=false;
         
         if(Buy_Or_Sell=="Buy") bool m3 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(Move_Stop_To_Pips*UsePoint),OrderTakeProfit(),0,Green); 
         if(Buy_Or_Sell=="Sell") bool m4 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(Move_Stop_To_Pips*UsePoint),OrderTakeProfit(),0,Red); 
      }
   }
return;
}
void OpenTrade()
{
   PlaceStops=true;
   
   double TheSpread=MarketInfo(Symbol(),MODE_SPREAD);
   
   if(Digits()==3 || Digits()==5) TheSpread = MarketInfo(Symbol(),MODE_SPREAD)/10;
   
   if(TheSpread>Max_Spread_Pips) {Print("Spread too large, can't place trade");return;}

   if(Buy_Or_Sell=="Buy")
   {
      Tickets[0] = OrderSend(Symbol(),OP_BUY,lotSize,Ask,UseSlippage,0,0,"Buy Trendline Trade: "+Symbol(),Magic,0,0);

      if(GetLastError()==4110) {BuysNotAllowed=true;return;}

      SendAlert("New Trendline Buy Trade on the "+Symbol());
   }
   if(Buy_Or_Sell=="Sell")
   {
      Tickets[0] = OrderSend(Symbol(),OP_SELL,lotSize,Bid,UseSlippage,0,0,"Sell Trendline Trade: "+Symbol(),Magic,0,0);

      if(GetLastError()==4111) {SellsNotAllowed=true;return;}
         
      SendAlert("New Trendline Sell Trade on the "+Symbol());
   }
return;
}
void SendAlert(string Message)
{
   if(Mail_Alert) SendMail("New Rollover Finch Alert",Message);
   if(PopUp_Alert) Alert(Message);
   if(Sound_Alert) PlaySound("alert.wav");
   if(SmartPhone_Notifications) SendNotification(Message);
   return;
}