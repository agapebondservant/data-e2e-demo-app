import { Component, OnInit } from '@angular/core';
import { Card, CardType, Location, RmqTransaction, Transaction } from 'src/app/app.model';
import { HttpClient } from '@angular/common/http';
import '@cds/core/icon/register.js';
import { alarmClockIcon, ClarityIcons, creditCardIcon, infoCircleIcon, userIcon, vmBugIcon } from '@cds/core/icon';
import { environment } from 'src/environments/environment';
import { DatePipe } from '@angular/common';

interface FraudTransaction {
  name: string;
  y: number;
}

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  constructor(
    private httpClient: HttpClient
  ) { }

  ngOnInit() {
    ClarityIcons.addIcons(vmBugIcon, userIcon, alarmClockIcon, creditCardIcon, infoCircleIcon);

    this.getTransactions(this.api);
    this.drawChart();
    this.startTransactions();
  }

  api: string = environment.API_ENDPOINT + '/demo';
  title = 'demo-ui';

  cards: Card[] = [
    { id: 1, number: '0020-1111-2222', type: CardType.CREDIT_CARD },
    { id: 2, number: '3333-4424-5555', type: CardType.CREDIT_CARD },
    { id: 3, number: '6662-7777-8888', type: CardType.DEBIT_CARD },
    { id: 4, number: '9999-9000-8010', type: CardType.CREDIT_CARD },
    { id: 5, number: '1232-1234-1234', type: CardType.DEBIT_CARD },
    { id: 6, number: '9876-5432-1198', type: CardType.CREDIT_CARD },
    { id: 7, number: '2581-9183-6121', type: CardType.DEBIT_CARD },
    { id: 8, number: '4322-1234-9876', type: CardType.CREDIT_CARD }
  ];
  locations: Location[] = [
    { id: 1, name: 'Bangalore', lat: 12.9716, lon: 77.5946 },
    { id: 2, name: 'Delhi', lat: 28.7041, lon: 77.1025 },
    { id: 3, name: 'Mumbai', lat: 19.0759, lon: 72.8766 },
    { id: 4, name: 'Hyderabad', lat: 17.3850, lon: 78.4867 },
    { id: 5, name: 'Chennai', lat: 13.0826, lon: 80.2707 },
    { id: 6, name: 'Kolkata', lat: 22.5626, lon: 88.3630 },
    { id: 7, name: 'Ahmedabad', lat: 23.0314, lon: 72.5713 },
    { id: 8, name: 'Pune', lat: 18.5204, lon: 73.8567 }
  ];

  transactions: Transaction[] = [];
  currentCard: any;
  currentAmount: any;
  currentTransactionType: any;
  currentLocation: any;
  interval: any;
  onGoingTransaction: boolean = false;
  chartOptions: any;
  showDetails: boolean = false;
  fraudTransaction: Transaction | undefined;

  public stop() {
    clearInterval(this.interval);
  }

  public delete() {
    this.httpClient
      .delete(this.api)
      .subscribe(res => {
        setTimeout(() => this.getTransactions(this.api), 2000);
      });
  }

  public showGraph(): boolean {
    return this.transactions.filter(transaction => transaction.isFraud).length > 0;
  }

  public getTransactionStatus(transaction: Transaction) {
    if (transaction.isFraud) {
      return "<span class='fraud'>Fraud Transaction</span>";
    }
    return "<span class='valid'>Valid Transaction</span>";
  }

  public showTransactionDetails(fraudTransaction: Transaction) {
    this.showDetails = true;
    this.fraudTransaction = fraudTransaction;
  }

  private startTransactions() {
    setTimeout(() => this.pickRandomTransaction(), 2000);
    this.interval = setInterval(() => this.pickRandomTransaction(), 5000);
  }

  private pickRandomTransaction() {
    const randomCard = this.cards[Math.floor(Math.random() * this.cards.length)];
    const randomLocation = this.locations[Math.floor(Math.random() * this.locations.length)];

    const now = new Date();
    const formattedDate = new DatePipe('en-US').transform(now, 'dd-MM-yyyyTHH:mm:ssZ');

    const transaction: RmqTransaction = {
      dateTime: formattedDate,
      transactionType: randomCard.type,
      cardNumber: randomCard.number,
      amount: this.randomIntFromInterval(10, 1000),
      location: randomLocation.name,
      lat: randomLocation.lat,
      lon: randomLocation.lon
    }

    this.onGoingTransaction = true;
    this.currentCard = transaction.cardNumber;
    this.currentAmount = transaction.amount;
    this.currentTransactionType = transaction.transactionType;
    this.currentLocation = transaction.location;

    this.save(this.api, transaction);
  }

  public getDateTime(dateTime: any) {
    const date = new Date(dateTime.replace('T', ' ').replace('Z', ''));
    const formattedDate = new DatePipe('en-US').transform(date, 'dd/MM/yyyy h:mm:ss.SSS a');
    return formattedDate;
  }

  private save(apiEndpoint: string, data: RmqTransaction): void {
    this.httpClient
      .post(apiEndpoint, data)
      .subscribe(res => {
        setTimeout(() => this.getTransactions(this.api), 2000);
      });
  }

  private getTransactions(apiEndpoint: string) {
    this.httpClient
      .get(apiEndpoint)
      .subscribe((res: any) => {
        this.onGoingTransaction = false;
        this.transactions = res.reverse();

        this.drawChart();
      })
  }

  private drawChart() {
    const fraudCountsByLocation = this.transactions.reduce((fraudCounts: any, transaction) => {
      if (transaction.isFraud) {
        if (fraudCounts[transaction.location]) {
          fraudCounts[transaction.location]++;
        } else {
          fraudCounts[transaction.location] = 1;
        }
      }
      return fraudCounts;
    }, {});

    const data: FraudTransaction[] = [];
    for (const key in fraudCountsByLocation) {
      data.push({name: key, y: fraudCountsByLocation[key]});
    }

    this.chartOptions = {
      animationEnabled: true,
      title: {
        text: "Fraud Transactions"
      },
      subtitles: [{
        text: "Transactions/location"
      }],
      data: [{
        type: "pie", //change type to column, line, area, doughnut, etc
        indexLabel: "{name}: {y}",
        dataPoints: data
      }]
    }
  }

  // This method is used for getting random amount for transaction; min and max included
  private randomIntFromInterval(min: number, max: number): string {
    return Math.floor(Math.random() * (max - min + 1) + min).toString()
  }
}
