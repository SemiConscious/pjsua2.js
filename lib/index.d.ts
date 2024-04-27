export * from '../swig/pjsua2';

declare module '../swig/pjsua2' {
  namespace std {
    interface coderInfoArray {
      [Symbol.iterator](): Iterator<Pjsua2.CoderInfo>;
    }
  }
}
