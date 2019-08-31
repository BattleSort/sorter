import consumer from "./consumer"

var user_id = Math.floor(Math.random() * 100) + 1;

// 各ユーザーは一意で推測不可能なidを付与したroomで対戦相手を待ち受ける
// consumer.subscriptions.create({ channel: "MatchChannel", level:1,category: 3 ,user_id: user_id}, {
//   connected() {
//     console.log("connected "+user_id);

//     // Called when the subscription is ready for use on the server
//   },
//   disconnected() {
//     console.log("disconnected");
//     // Called when the subscription has been terminated by the server
//   },
//   received(data) {
//     // Called when there's incoming data on the websocket for this channel
//     console.log(data);
//   },
//   mes(message) {
//     this.perform("mes", {message : message});
//   }
// });
