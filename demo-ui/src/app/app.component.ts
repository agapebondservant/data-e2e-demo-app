import { DatePipe } from '@angular/common';
import { Component } from '@angular/core';
import { Card, CardType, DateTime, Location, Transaction } from 'src/app/app.model';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent {
  constructor(
    private datePipe: DatePipe,
    private httpClient: HttpClient
  ) {
    this.getTransactions(this.api);
  }
  
  api: string = 'http://localhost:8090/demo';
  title = 'demo-ui';
  amount: string = '0.0';
  
  cards: Card[] = [
    { id: 1, number: '0000-1111-2222', type: CardType.CREDIT_CARD },
    { id: 2, number: '2222-1111-0000', type: CardType.CREDIT_CARD },
    { id: 3, number: '1111-0000-2222', type: CardType.CREDIT_CARD },
  ];
  locations: Location[] = [
    { id: 1, name: 'Bangalore', lat: 20.00, lon: 20.00 },
    { id: 2, name: 'Mumbai', lat: 25.00, lon: 19.00 },
    { id: 3, name: 'Delhi', lat: 40, lon: 23.00 },
  ];
  dateTimes: DateTime[] = [
    { name: 'Mar 07, 10:15 AM', value: '2023-03-07T10:15:30' },
    { name: 'Mar 08, 10:05 AM', value: '2023-03-08T10:05:30' },
    { name: 'Mar 01, 05:20 AM', value: '2023-03-01T05:20:20' }
  ];

  transactions: Transaction[] = [];
  selectedCard: Card = this.cards[0];
  selectedLocation: Location = this.locations[0];
  selectedDateTime: DateTime = this.dateTimes[0];

  onSubmit() {
    const transaction: Transaction = {
      dateTime: this.selectedDateTime.value,
      transactionType: this.selectedCard.type,
      cardNumber: this.selectedCard.number,
      amount: this.amount,
      location: this.selectedLocation.name,
      lat: this.selectedLocation.lat,
      lon: this.selectedLocation.lon
    }
    this.save(this.api, transaction);
  }

  private save(apiEndpoint: string, data: any): void {
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
        this.transactions = res;
      })
  }
}
