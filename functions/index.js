const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);
var email;

exports.notification1 = functions.firestore.document('chats/{chatId}/chat/{messages}')
    .onCreate((snapshot, context) => {
        const email = String(snapshot.data().sentTo);

        return admin.firestore().collection('users').doc(email).collection('tokens').get()
            .then(snapshotData => {
                var tokens = [];

                if (snapshotData.empty) {
                    console.log('No Devices');
                    throw new Error('No Devices');
                } else {
                    for (var token of snapshotData.docs) {
                        tokens.push(token.data().token);
                    }

                    var payload = {
                        notification: {
                            title: snapshot.data().username,
                            body: snapshot.data().text,
                            click_action: 'FLUTTER_NOTIFICATION_CLICK'
                        },
                    }
                    return admin.messaging().sendToDevice(tokens, payload)
                }

            })
            .catch((err) => {
                console.log(err);
                return null;
            })

    });
exports.notification2 = functions.firestore.document('groups/{id}/chat/{messages}')
    .onCreate(async (snapshot, context) => {
        var members = [];
        var tokens = [];
        const id = snapshot.data().chatId;
        return admin.firestore()
            .collection('groups')
            .doc(id)
            .collection('members')
            .get()
            .then(membersData => {
                if (membersData.empty) {
                    console.log('No members');
                    throw new Error('No members');
                } else {
                    for (var member of membersData.docs) {
                        members.push(member.data().email);
                    }
                    console.log(members);
                }
                return null;
            }).catch((err) => {
                console.log(err);
                return null;
            }).then(async (_) => {
                //var user = String(snapshot.data().username).italics;

                for (var member of members) {
                    var temp = admin.firestore()
                        .collection('users')
                        .doc(member)
                        .collection('tokens').get().then((tokenData) => {
                            tokens.push(tokenData.docs[0].data().token);
                            return null;
                        })

                }
                return admin.firestore().collection('groups').doc(id).get();
                // return members.forEach((mail) => {
                //     admin.firestore()
                //         .collection('users')
                //         .doc(mail)
                //         .collection('tokens')
                //         .get()
                //         .then(tokenData => {
                //             //tokens.push(tokenData.docs[0].data().token);

                //             return admin.messaging().sendToDevice(tokenData.docs[0].id, payload);

                //         }).catch((err) => {
                //             console.log(err);
                //             return null;
                //         })
                // });
            }).then((groupData) => {
                var payload = {
                    notification: {
                        title: groupData.data().group_name,//snapshot.data().username,
                        body: snapshot.data().username + ':  ' + snapshot.data().text,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    }
                };
                return admin.messaging().sendToDevice(tokens, payload);
            })
    });