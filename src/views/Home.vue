<template>
  <v-app>
    <v-row no-gutters>
      <template v-if="showCallUI">
        <CallUI
          :changeAudio="changeAudio"
          :changeVideo="changeVideo"
          :connectedUsers="classSessionConnectedUsers"
          :endCallSession="endCallSession"
          :isCallPublisher="isPublisher"
          :startDesktopSharing="startDesktopSharing"
          :stopDesktopSharing="stopDesktopSharing"
        />
      </template>

      <template v-else>
        <v-col :cols="$vuetify.breakpoint.smAndDown ? '2' : '1'">
          <SideBar
            :key="sideBarKey"
            :highlightedSidebarOption="highlightedSidebarOption"
            :unreadNotifications="unreadNotifications"
            :unreadRoomMessages="unreadRoomMessages"
            :activateNotificationDialog="activateNotificationDialog"
            :activateAddRoomDialog="activateAddRoomDialog"
            :deactivateAllDialogs="deactivateAllDialogs"
            :showAvailableRooms="showAvailableRooms"
          />
        </v-col>

        <v-col v-if="showAddRoomDialog">
          <CreateRoom ref="createRoom" :createRoom="createRoom" />
        </v-col>
        <v-col v-else-if="showNotificationDialog">
          <Notification :joinRequests="joinRequests" :joinRoom="joinRoom" />
        </v-col>

        <v-col
          v-else-if="showAvailableRoomsPage"
          :cols="$vuetify.breakpoint.smAndDown ? '10' : '11'"
        >
          <v-row no-gutters>
            <v-col cols="3">
              <RoomsPage
                :key="roomsPageKey"
                :sendWSMessage="sendWSMessage"
                :changeViewedRoomIndex="changeViewedRoomIndex"
                :indexOfCurrentViewedRoom="indexOfCurrentViewedRoom"
                :joinedRooms="joinedRooms"
                :unreadRoomMessages="unreadRooms"
              />
            </v-col>
            <v-col cols="9">
              <ChatPage
                :key="chatPageKey"
                v-if="showChatPage"
                :associatesMap="associatesNameMap"
                :associates="associatesOnline"
                :sendWSMessage="sendWSMessage"
                :currentViewedRoom="currentViewedRoom"
                :clearFetchedUsers="clearFetchedUsers"
                :fetchedUsers="fetchedUsers"
                :joinCallSession="joinCallSession"
                :startCallSession="startCallSession"
              />
            </v-col>
          </v-row>
        </v-col>
      </template>
    </v-row>

    <v-dialog persistent width="400px" v-model="showDialog">
      <v-card>
        <v-card-text>
          <div align="center" justify="center">
            <v-row>
              <v-col cols="12">
                <span>{{ dialogError }}</span>
              </v-col>
              <v-col>
                <v-row justify="center">
                  <v-btn
                    text
                    depressed
                    color="green"
                    @click="showDialog = false"
                  >
                    Close
                  </v-btn>
                  <v-btn
                    depressed
                    text
                    color="red"
                    v-if="socketClosed"
                    @click="connectWebsocket"
                  >
                    Reconnect
                  </v-btn>
                </v-row>
              </v-col>
            </v-row>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<script lang="ts">
let socket: WebSocket;

let videoTransceiver: any;
let audioTransceiver: any;

let videoTrack: MediaStreamTrack;
let audioTrack: MediaStreamTrack;
let stream: MediaStream;

let peerConnection: RTCPeerConnection;

// @ is an alias to /src
import SideBar from "@/components/SideBar.vue";
import CreateRoom from "@/components/CreateRoom.vue";
import RoomsPage from "@/components/RoomsPage.vue";
import ChatPage from "@/components/ChatPage.vue";
import Notification from "@/components/Notification.vue";
import CallUI from "@/components/CallUI.vue";

import store from "@/store";

import Vue from "vue";

import {
  JoinedRoom,
  RoomPageDetails,
  JoinRequest,
  Message,
  FetchedUsers,
  UsersOnline,
} from "../Types";
import { WSMessageType, SideBarOptions } from "../Constants";

export default Vue.extend({
  name: "Home",

  components: {
    SideBar,
    CreateRoom,
    RoomsPage,
    ChatPage,
    Notification,
    CallUI,
  },

  data: () => ({
    showNotificationDialog: false,
    showAddRoomDialog: false,
    showAvailableRoomsPage: true,
    showChatPage: false,
    showCallUI: false,

    isPublisher: false,

    highlightedSidebarOption: "Rooms",

    unreadRoomMessages: 0,
    unreadNotifications: 0,
    indexOfCurrentViewedRoom: 0,

    sideBarKey: 0,
    roomsPageKey: 0,
    chatPageKey: 0,
    callPageKey: 0,

    joinedRooms: [] as JoinedRoom[],
    fetchedUsers: [] as FetchedUsers[],
    joinRequests: [] as JoinRequest[],

    classSessionConnectedUsers: {} as UsersOnline,

    currentViewedRoom: {} as RoomPageDetails,

    associatesOnline: new Map() as Map<string, boolean>,
    associatesNameMap: new Map() as Map<string, string>,
    unreadRooms: new Map() as Map<string, boolean>,

    dialogError: "This is a dialog error",
    showDialog: false,

    socketClosed: false,
  }),

  methods: {
    startCallSession: function () {
      this.showCallUI = true;
      this.isPublisher = true;

      this.classSessionConnectedUsers = {};
      this.classSessionConnectedUsers[store.state.userID] = {
        name: store.state.userID,
        isOnline: true,
      };

      peerConnection = new RTCPeerConnection({
        iceServers: [
          {
            urls: ["stun:stun.l.google.com:19302"],
          },
        ],
      });

      peerConnection.oniceconnectionstatechange = () => {
        console.log("ICE connection state", peerConnection.iceConnectionState);

        if (peerConnection.iceConnectionState === "failed") {
          // Show error page so that users can choose to disconnect call.
          this.dialogError = "Peer connection failed.";
          this.showDialog = true;
        }
      };

      peerConnection.onicecandidate = (event) => {
        console.log("New candidate added", event);

        if (
          event.candidate === null &&
          peerConnection.localDescription &&
          peerConnection.localDescription.sdp &&
          peerConnection.iceConnectionState === "new"
        ) {
          const message = {
            msgType: WSMessageType.StartClassSession,
            sdp: peerConnection.localDescription.sdp,
            roomID: this.currentViewedRoom.roomID,
          };

          socket.send(JSON.stringify(message));
        }
      };

      peerConnection.onnegotiationneeded = (event) => {
        console.log("Negotiation needed", event);
      };

      const MediaConstraints = {
        video: { width: 640, height: 480 },
        audio: true,
      };

      this.getUserMedia(MediaConstraints, (e: MediaStream) => {
        videoTrack = e.getVideoTracks()[0];
        audioTrack = e.getAudioTracks()[0];

        audioTransceiver = peerConnection.addTransceiver(audioTrack, {
          direction: "sendrecv",
        });

        videoTransceiver = peerConnection.addTransceiver(videoTrack, {
          direction: "sendrecv",
        });

        const el = document.getElementById("videoID") as HTMLVideoElement;

        if (!el) {
          this.dialogError = "Error getting video element.";
          this.showDialog = true;
          console.log("Could not get video ID element");
          return;
        }

        const mediaStreamTrack = [videoTrack];
        stream = new MediaStream(mediaStreamTrack);

        el.srcObject = stream;
        el.autoplay = true;

        peerConnection
          .createOffer()
          .then((sdp) => {
            peerConnection.setLocalDescription(sdp);
          })
          .catch((log) =>
            console.log("Error creating peer connection offer, error:", log)
          );
      });

      peerConnection.ontrack = ({ transceiver, streams: [event] }) => {
        event.onaddtrack = (event) => {
          console.log("On add track called for start video session.");
          stream.addTrack(event.track);
          console.log(event.track.id);
        };

        event.onremovetrack = (event) => {
          console.log("On remove track called for start video session.");
          stream.removeTrack(event.track);
          console.log(event.track.id);
        };

        transceiver.receiver.track.onmute = () => {
          console.log("Track muted for start session.");
        };

        transceiver.receiver.track.onended = () => {
          console.log("Track ended for start session");

          const id = event.id;

          this.classSessionConnectedUsers[id] = {
            name: id,
            isOnline: false,
          };

          this.callPageKey++;
        };

        transceiver.receiver.track.onunmute = () => {
          console.log("Track started for start session.");
          console.log("track", transceiver, "\n event", event);

          const id = event.id;
          this.classSessionConnectedUsers[id] = {
            name: id,
            isOnline: true,
          };

          stream.addTrack(transceiver.receiver.track);
        };
      };
    },

    joinCallSession: function (sessionData: Message) {
      this.showCallUI = true;
      this.isPublisher = false;
      this.classSessionConnectedUsers = {};

      peerConnection = new RTCPeerConnection({
        iceServers: [
          {
            urls: ["stun:stun.l.google.com:19302"],
          },
        ],
      });

      peerConnection.oniceconnectionstatechange = () => {
        console.log(peerConnection.iceConnectionState);

        if (peerConnection.iceConnectionState === "failed") {
          this.dialogError = "Connection state failed";
          this.showDialog = true;
        }
      };

      peerConnection.onnegotiationneeded = (event) => {
        console.log("Negotiation needed", event);
      };

      peerConnection.onicecandidate = (event) => {
        console.log("A new user added", event);

        if (
          event.candidate == null &&
          peerConnection.localDescription &&
          peerConnection.localDescription.sdp &&
          peerConnection.iceConnectionState === "new"
        ) {
          console.log("Calling join class session");

          const message = {
            msgType: WSMessageType.JoinClassSession,
            sdp: peerConnection.localDescription.sdp,
            roomID: this.currentViewedRoom.roomID,
            sessionID: sessionData.message,
          };
          socket.send(JSON.stringify(message));
        }
      };

      const MediaConstraints = {
        audio: true,
      };

      this.getUserMedia(MediaConstraints, (e: MediaStream) => {
        console.log("Adding audio track");
        audioTrack = e.getAudioTracks()[0];
        audioTrack.enabled = true;
        audioTransceiver = peerConnection.addTransceiver(audioTrack, {
          direction: "sendrecv",
        });

        const el = document.getElementById("videoID") as HTMLVideoElement;

        if (!el) {
          this.dialogError = "Error getting video element.";
          this.showDialog = true;

          console.log("Could not get video ID element");
          return;
        }

        stream = new MediaStream();

        el.srcObject = stream;
        el.autoplay = true;

        console.log("Sending to server to create offer.");
        peerConnection
          .createOffer()
          .then((sdp) => {
            peerConnection.setLocalDescription(sdp);
          })
          .catch((log) => {
            console.log("Error creating offer on join session, error:", log);
            this.dialogError = "Error creating peer offer";
            this.showDialog = true;
          });
      });

      peerConnection.ontrack = ({ transceiver, streams: [event] }) => {
        event.onaddtrack = (event) => {
          console.log("On add track called for join video session");
          stream.addTrack(event.track);
          console.log("track ID", event.track.id);
        };

        event.onremovetrack = (track) => {
          console.log("On remove track called for join video session.");
          stream.removeTrack(track.track);
          console.log(track.track.id);

          const id = track.track.id;
          delete this.classSessionConnectedUsers[id];

          this.callPageKey++;
        };

        transceiver.receiver.track.onmute = () =>
          console.log("Track muted for join session");

        transceiver.receiver.track.onended = () => {
          console.log("Track ended for Join session");
        };

        transceiver.receiver.track.onunmute = () => {
          if (transceiver.receiver.track.kind === "audio") {
            const id = transceiver.receiver.track.id;
            this.classSessionConnectedUsers[id] = {
              name: event.id,
              isOnline: true,
            };
          }

          console.log("Track unmuted");

          console.log("Track started for Join session");

          console.log("track", transceiver, "\n event", event);
          stream.addTrack(transceiver.receiver.track);
        };
      };
    },

    endCallSession: function () {
      this.showCallUI = false;

      if (audioTrack) {
        audioTrack.enabled = false;
        audioTrack.stop();
        audioTransceiver.stop();
      }

      if (videoTrack) {
        videoTrack.enabled = false;
        videoTrack.stop();
        videoTransceiver.stop();
      }

      if (peerConnection) peerConnection.close();

      this.isPublisher = false;
      console.log("sending websocket peer close message");
    },

    changeVideo: function () {
      videoTrack.enabled = !videoTrack.enabled;

      videoTrack.enabled
        ? videoTransceiver.sender.replaceTrack(videoTrack)
        : videoTransceiver.sender.replaceTrack(null);
    },

    changeAudio: function () {
      audioTrack.enabled = !audioTrack.enabled;
      audioTrack.enabled
        ? audioTransceiver.sender.replaceTrack(audioTrack)
        : audioTransceiver.sender.replaceTrack(null);
    },

    getUserMedia: function (
      mediaConstraints: any,
      onMedia: (e: MediaStream) => void
    ) {
      navigator.mediaDevices
        .getUserMedia(mediaConstraints)
        .then(function (e) {
          onMedia(e);
        })
        .catch((error) => {
          console.log("Error getting media device, error:", error);
          this.dialogError = "Error starting media devices";
          this.showDialog = true;
        });
    },

    startDesktopSharing: function () {
      // 480p video constraints.
      const mediaConstraints = { video: { width: 640, height: 480 } };

      navigator.mediaDevices
        .getDisplayMedia(mediaConstraints)
        .then((event) => {
          // Disable webcam and remove video from stream.
          videoTrack.enabled = false;
          stream.removeTrack(videoTrack);

          const tracks = event.getVideoTracks();
          this.addTracks(tracks);

          if (tracks.length > 0) {
            videoTransceiver.sender.replaceTrack(tracks[0]);
          } else {
            console.log("Could not find any track for desktop sharing");

            this.dialogError = "Could not get track for desktop sharing.";
            this.showDialog = true;
          }
        })
        .catch((error) => {
          console.log("Error creating desktop sharing", error);
          this.dialogError = "Error starting desktop sharing.";
          this.showDialog = true;
        });
    },

    stopDesktopSharing: function (isVideoOn: boolean) {
      const tracks = stream.getVideoTracks();
      this.removeTracks(tracks);

      videoTrack.enabled = isVideoOn;
      stream.addTrack(videoTrack);

      videoTransceiver.sender.replaceTrack(videoTrack);
    },

    removeTracks: function (tracks: MediaStreamTrack[]) {
      for (let i = 0; i < tracks.length; i++) {
        tracks[i].enabled = false;
        stream.removeTrack(tracks[i]);
      }
    },

    addTracks: function (tracks: MediaStreamTrack[]) {
      for (let i = 0; i < tracks.length; i++) {
        stream.addTrack(tracks[i]);
      }
    },

    activateNotificationDialog: function () {
      this.showAddRoomDialog = false;
      this.showAvailableRoomsPage = false;
      this.showNotificationDialog = true;

      this.highlightedSidebarOption = SideBarOptions.Notifications;
    },

    activateAddRoomDialog: function () {
      this.showAddRoomDialog = true;
      this.showNotificationDialog = false;
      this.showAvailableRoomsPage = false;

      this.highlightedSidebarOption = SideBarOptions.AddRoom;
    },

    showAvailableRooms: function () {
      this.showAvailableRoomsPage = true;
      this.showAddRoomDialog = false;
      this.showNotificationDialog = false;

      this.highlightedSidebarOption = SideBarOptions.Rooms;
    },

    deactivateAllDialogs: function () {
      this.showAddRoomDialog = false;
      this.showNotificationDialog = false;
      this.showAvailableRoomsPage = true;

      this.highlightedSidebarOption = SideBarOptions.Rooms;

      setTimeout(() => {
        this.sideBarKey++;
        this.roomsPageKey++;
      }, 1);
    },

    scrollToBottomOfChatPage: function () {
      this.$nextTick(() => {
        const scrollHeight = document.querySelector("#messages");
        if (scrollHeight) {
          scrollHeight.scrollTop = scrollHeight.scrollHeight;
        }
      });

      console.log("Scrolling to bottom");
    },

    changeViewedRoomIndex: function (index: number) {
      console.log(index, "room name");
      this.indexOfCurrentViewedRoom = index;
      this.unreadRooms.set(this.joinedRooms[index]._id, false);

      this.currentViewedRoom.messageCount =
        this.joinedRooms[this.indexOfCurrentViewedRoom].messageCount;

      this.currentViewedRoom.roomName =
        this.joinedRooms[this.indexOfCurrentViewedRoom].roomName;

      this.currentViewedRoom.roomID =
        this.joinedRooms[this.indexOfCurrentViewedRoom]._id;

      let count = 0;
      for (const v of this.unreadRooms.values()) {
        if (v == true) {
          count++;
        }
      }

      this.unreadRoomMessages = count;

      this.chatPageKey++;

      console.log(this.currentViewedRoom);
    },

    clearFetchedUsers: function () {
      this.fetchedUsers = [];
    },

    sendWSMessage: function (message: string) {
      socket.send(message);
    },

    createRoom: function (roomName: string) {
      this.showAddRoomDialog = false;
      this.showAvailableRoomsPage = true;

      console.log(this.$store.state.userID, "user ID");
      const message = {
        msgType: WSMessageType.CreateRoom,
        userID: this.$store.state.userID,
        roomName: roomName,
        roomIcon: "",
      };

      socket.send(JSON.stringify(message));
      console.log("sent create room message", roomName);
    },

    joinRoom: function (joined: boolean, index: number) {
      const message = {
        msgType: WSMessageType.JoinRoom,
        _id: this.joinRequests[index]._id,
        userID: store.state.userID,
        roomID: this.joinRequests[index].roomID,
        userToJoinID: this.joinRequests[index].userToJoinID,
        roomName: this.joinRequests[index].roomName,
        accepted: false,
        rejectRoom: false,
        exitedRoom: false,
      };
      if (joined) {
        message["accepted"] = true;
      } else {
        message["rejectRoom"] = true;
      }

      socket.send(JSON.stringify(message));
      this.joinRequests.splice(index, 1);
      this.unreadNotifications = this.joinRequests.length;
    },

    connectWebsocket: function () {
      if (this.$store.state.token == "") {
        this.$router.push("/login");
        return;
      }

      const URL: string = process.env.VUE_APP_BACKEND_SERVER;
      const URLs = URL.split("https://");

      console.log("Connecting websocket");

      if (URLs.length != 2) {
        this.$router.push("/login");
        return;
      }

      socket = new WebSocket(
        `wss://${URLs[1]}/ws/${this.$store.state.userID}/${this.$store.state.wsTicket}`
      );

      socket.onopen = (e: Event) => {
        this.showDialog = false;
        console.log("Websocket Opened", e);

        const message = {
          msgType: WSMessageType.WebsocketOpen,
        };

        socket.send(JSON.stringify(message));
      };

      socket.onclose = (e: CloseEvent) => {
        console.log(e);
      };

      socket.onmessage = this.onWSMessage;

      socket.onerror = (event: Event) => {
        // Reconnect Websocket if not UnAuthorized.
        console.log("Websocket errored.", event);

        this.dialogError = "Websocket connection error.";
        this.showDialog = true;
        this.socketClosed = true;
      };
    },

    onWSMessage: function (event: MessageEvent) {
      const jsonContent = JSON.parse(event.data);

      console.log("received message", jsonContent.msgType);

      switch (jsonContent.msgType) {
        case WSMessageType.WebsocketOpen:
          jsonContent.onlineAssociates.forEach((associate: string) => {
            this.associatesOnline.set(associate, true);
          });

          if (jsonContent.joinedRooms) {
            this.joinedRooms = jsonContent.joinedRooms.data;
          }
          this.joinedRooms.forEach((room: JoinedRoom) => {
            this.unreadRooms.set(room._id, false);
          });

          this.associatesNameMap = jsonContent.associates;

          this.joinRequests = jsonContent.joinRequests.data;

          console.log(this.joinRequests);
          console.log("jsjs");
          console.log(jsonContent.joinRequests);
          this.unreadNotifications = jsonContent.joinRequests.count;
          break;

        case WSMessageType.JoinRoom:
          this.onCreateRoom(jsonContent.data);
          break;

        case WSMessageType.RequestMessages:
          this.onRequestMessage(jsonContent.data.data);
          break;

        case WSMessageType.NewMessage:
          this.onNewMessage(jsonContent.data);
          break;

        case WSMessageType.SearchUser:
          this.fetchedUsers = jsonContent.data.data;
          console.log(jsonContent);
          break;
      }
    },

    onNewMessage: function (message: Message) {
      // TODO: Notify Users of room
      if (this.currentViewedRoom.roomID == message.roomID) {
        if (this.currentViewedRoom.messages == undefined) {
          this.currentViewedRoom.messages = [];
        }
        this.currentViewedRoom.messages.push(message);
        this.chatPageKey++;
      }
      this.scrollToBottomOfChatPage();
    },

    onRequestMessage: function (messages: [Message]) {
      console.log(messages[0]);
      this.showChatPage = true;

      this.currentViewedRoom.messages = messages;
      this.chatPageKey++;
      this.scrollToBottomOfChatPage();
    },

    onCreateRoom: function (data: JoinedRoom) {
      this.joinedRooms.unshift(data);
      this.indexOfCurrentViewedRoom++;
      // TODO: Fix this
      // this.unreadRoomMessages++;

      this.deactivateAllDialogs();
    },
  },

  mounted() {
    console.log("runs");
    this.connectWebsocket();
  },
});
</script>
