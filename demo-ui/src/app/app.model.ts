export interface Transaction {
  dateTime: string | undefined;
  transactionType: CardType;
  cardNumber: string;
  amount: string;
  location: string;
  lat: number;
  lon: number;
  isFraud?: boolean;
}

export interface Card {
  id: number;
  number: string;
  type: CardType
}

export interface Location {
  id: number;
  name: string;
  lat: number;
  lon: number;
}

export interface DateTime {
  name: string;
  value: string;
}

export enum CardType {
  CREDIT_CARD = "CREDIT_CARD",
  DEBIT_CARD = "DEBIT_CARD"
}