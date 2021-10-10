<template>
  <v-app>
    <v-row no-gutters>
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

// @ is an alias to /src
import SideBar from "@/components/SideBar.vue";
import CreateRoom from "@/components/CreateRoom.vue";
import RoomsPage from "@/components/RoomsPage.vue";
import ChatPage from "@/components/ChatPage.vue";
import Notification from "@/components/Notification.vue";
import store from "@/store";

import Vue from "vue";

import {
  JoinedRoom,
  RoomPageDetails,
  JoinRequest,
  Message,
  FetchedUsers,
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
  },

  data: () => ({
    showNotificationDialog: false,
    showAddRoomDialog: false,
    showAvailableRoomsPage: true,
    showChatPage: false,

    highlightedSidebarOption: "Rooms",

    unreadRoomMessages: 0,
    unreadNotifications: 0,
    indexOfCurrentViewedRoom: 0,

    sideBarKey: 0,
    roomsPageKey: 0,
    chatPageKey: 0,

    joinedRooms: [] as JoinedRoom[],
    fetchedUsers: [] as FetchedUsers[],
    joinRequests: [] as JoinRequest[],

    currentViewedRoom: {} as RoomPageDetails,

    associatesOnline: new Map() as Map<string, boolean>,
    associatesNameMap: new Map() as Map<string, string>,
    unreadRooms: new Map() as Map<string, boolean>,

    dialogError: "This is a dialog error",
    showDialog: true,

    socketClosed: false,
  }),

  methods: {
    startCallSession: function () {
      console.log("Hello");
    },

    joinCallSession: function () {
      console.log("Hello");
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
