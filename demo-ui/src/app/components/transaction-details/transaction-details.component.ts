import { DatePipe } from '@angular/common';
import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Transaction } from 'src/app/app.model';

@Component({
  selector: 'app-transaction-details',
  templateUrl: './transaction-details.component.html',
  styleUrls: ['./transaction-details.component.scss']
})
export class TransactionDetailsComponent {

  @Input()
  showDetails: boolean = false;
  @Input()
  data: Transaction | undefined;
  @Output()
  close: EventEmitter<any> = new EventEmitter();

  public closeModal() {
    this.showDetails = false;
    this.close.emit();
  }

  public getDateTime(dateTime: any) {
    const date = new Date(dateTime);
    const formattedDate = new DatePipe('en-US').transform(date, 'dd/MM/yyyy h:mm:ss.SSS a');
    return formattedDate;
  }

  public totalTimeTaken(date1String: any, date2String: any) {
    const date1 = new Date(date1String);
    const date2 = new Date(date2String);
    const diffInSeconds = date2.getTime() - date1.getTime();
    return diffInSeconds;
  }
}
