<template>
  <v-row no-gutters>
    <v-col cols="12" style="height: 10vh">
      <v-app-bar tile flat height="80vh">
        <v-app-bar-nav-icon>
          <v-avatar>
            <!-- TODO: We should be able to use our own pic -->
            <v-img class="mx-2" :src="require('../assets/unilag.svg')"></v-img>
          </v-avatar>
        </v-app-bar-nav-icon>

        <v-toolbar-title
          style="width: 28vw"
          class="d-inline-block text--secondary"
        >
          <b>{{ currentViewedRoom.roomName }}</b>
        </v-toolbar-title>

        <v-spacer></v-spacer>

        <v-menu
          v-model="showAddUsersDialog"
          left
          rounded
          :close-on-content-click="false"
          offset-y
        >
          <template v-slot:activator="{ on, attrs }">
            <v-btn
              v-bind="attrs"
              v-on="on"
              icon
              :x-large="!$vuetify.breakpoint.smAndDown"
            >
              <v-icon>mdi-account-multiple-plus-outline</v-icon>
            </v-btn>
          </template>

          <v-card align="center">
            <v-row style="max-width: 40vh" align="center" justify="center">
              <v-col cols="12"></v-col>
              <v-col cols="12" sm="8">
                <v-text-field
                  v-model="searchUserName"
                  append-icon="mdi-magnify"
                  @keyup.enter.exact="searchUsers"
                  @click:append="searchUsers"
                  rounded
                  filled
                  placeholder="Search for contact email"
                />
              </v-col>

              <v-col cols="12">
                <v-container
                  fluid
                  class="ml-auto overflow-y-auto scroll-behavior-smooth"
                  style="max-height: 40vh"
                >
                  <v-checkbox
                    class="text--truncate"
                    dense
                    multiple
                    v-for="(user, i) in fetchedUsers"
                    :key="i"
                    :label="`${user.firstName} ${user.lastName} [ ${user.email} ]`"
                    :value="user._id"
                    v-model="selectedUsersToAddToRoom"
                  ></v-checkbox>
                </v-container>
              </v-col>
            </v-row>

            <v-card-actions>
              <v-btn @click="closeAddUserDialog" color="red" text>exit</v-btn>
              <v-btn
                @click="requestUserToJoinRoom"
                :disabled="selectedUsersToAddToRoom.length === 0"
                color="green"
                text
                >add users</v-btn
              >
            </v-card-actions>
          </v-card>
        </v-menu>

        <v-btn
          @click="startCallSession"
          icon
          :x-large="!$vuetify.breakpoint.smAndDown"
        >
          <v-icon>mdi-video</v-icon>
        </v-btn>

        <v-menu
          v-model="showOnlineUsersDialog"
          left
          :close-on-content-click="false"
          nudge-width="300"
          offset-y
        >
          <template v-slot:activator="{ on, attrs }">
            <v-btn
              v-bind="attrs"
              v-on="on"
              icon
              :x-large="!$vuetify.breakpoint.smAndDown"
            >
              <v-icon>mdi-information</v-icon>
            </v-btn>
          </template>

          <v-card max-width="50wh">
            <v-row class="mx-10">
              <v-col cols="12"></v-col>
              <v-col
                cols="12"
                v-for="(onlineUser, index) in currentViewedRoom.registeredUsers"
                :key="index"
              >
                <template v-if="onlineUser == userID">
                  <v-badge inline dot color="green"></v-badge>
                  <span class="mx-4">
                    <b>You</b>
                  </span>
                </template>

                <template v-else>
                  <v-badge
                    inline
                    dot
                    :color="
                      associates[onlineUser] &&
                      associates[onlineUser].isOnline === true
                        ? 'green'
                        : 'red'
                    "
                  ></v-badge>
                  <span class="mx-4">
                    <b class="d-inline-block text--secondary"
                      >{{
                        associates[onlineUser]
                          ? associates[onlineUser].name
                          : ""
                      }}
                      {{ onlineUser }}</b
                    >
                  </span>
                </template>
              </v-col>
            </v-row>

            <v-card-actions>
              <v-spacer></v-spacer>
              <v-btn @click="exitRoom" color="red" text>exit room</v-btn>
              <v-spacer></v-spacer>
            </v-card-actions>
          </v-card>
        </v-menu>
      </v-app-bar>
    </v-col>

    <v-col cols="12" style="height: 78vh">
      <v-container
        id="messages"
        class="overflow-y-auto scroll-behavior-smooth"
        style="height: 75vh"
        fluid
      >
        <v-row v-scroll:#messages="onScroll" dense>
          <v-col
            cols="12"
            v-for="(message, index) in currentViewedRoom.messages"
            :key="index"
          >
            <template v-if="message.type === messageType.Message">
              <v-row
                dense
                no-gutters
                align="end"
                justify="end"
                v-if="message.userID === userID"
              >
                <v-card
                  flat
                  :color="vuetify.framework.theme.dark ? '#778899' : '#bbeaff'"
                  max-width="65%"
                >
                  <v-card-text align="left" class="text--wrap">
                    <b>{{ message.message }}</b>
                  </v-card-text>

                  <v-card-subtitle align="right"
                    >{{ associatesMap[message.userID] }}
                    {{ message.createdAt }}</v-card-subtitle
                  >
                </v-card>
              </v-row>

              <v-row no-gutters dense v-else>
                <v-avatar class="mx-2" style="align-self: flex-end" rounded>
                  <v-img
                    height="50px"
                    width="50px"
                    contain
                    :src="require('../assets/unilag.svg')"
                  ></v-img>
                </v-avatar>
                <v-card
                  flat
                  :color="vuetify.framework.theme.dark ? '' : '#DCDCDC'"
                  max-width="65%"
                >
                  <v-card-text>
                    <b>{{ message.message }}</b>
                  </v-card-text>
                  <v-card-subtitle align="right" class="ml-auto">
                    <b
                      >{{ associatesMap[message.userID] }}
                      {{ message.createdAt }}</b
                    >
                  </v-card-subtitle>
                </v-card>
              </v-row>
            </template>

            <template v-else>
              <v-row>
                <v-col
                  class="mt-2"
                  v-if="message.type === messageType.Info"
                  cols="12"
                >
                  <div align="center">
                    <v-chip>
                      <b
                        style="max-width: 55vw"
                        class="d-inline-block text--secondary"
                        >{{ message.message }}.</b
                      >
                    </v-chip>
                  </div>
                </v-col>

                <v-col
                  class="mt-2"
                  v-if="message.type === messageType.ClassSession"
                  cols="12"
                >
                  <div align="center">
                    <v-chip @click="joinCallSession(message)">
                      <b
                        style="max-width: 60vw"
                        class="d-inline-block text--secondary"
                        >Class session started by {{ message.name }}. Click to
                        join.</b
                      >
                    </v-chip>
                  </div>
                </v-col>
              </v-row>
              <!-- 
              <v-col
                v-if="message.type === messageType.ClassSessionLink"
                cols="12"
              >
                <div align="center">
                  <v-chip @click="downloadSession(chat.message)">
                    <b
                      style="max-width: 60vw"
                      class="d-inline-block text--secondary"
                      >Class session recording by {{ message.name }}. Click to
                      download.</b
                    >
                  </v-chip>
                </div>
              </v-col> -->
            </template>
          </v-col>
        </v-row>
      </v-container>
    </v-col>

    <v-col cols="12" style="height: 10vh">
      <v-expand-transition>
        <v-textarea
          class="mx-5"
          v-show="showTextField"
          v-model="messageContent"
          prepend-inner-icon="mdi-emoticon"
          append-outer-icon="mdi-send"
          solo
          hide-details="auto"
          clearable
          no-resize
          rows="3"
          rounded
          @click:append-outer="sendMessage"
          @keyup.enter.exact="sendMessage"
        ></v-textarea>
      </v-expand-transition>
    </v-col>
  </v-row>
</template>

<script lang="ts">
"use strict";

import Vue from "vue";
import vuetify from "@/plugins/vuetify";
import { Prop } from "vue/types/options";
import store from "@/store";

import { RoomPageDetails, FetchedUsers, UsersOnline } from "../Types";

import { WSMessageType, MessageType } from "../Constants";

export default Vue.extend({
  name: "ChatPage",

  props: {
    currentViewedRoom: {} as Prop<RoomPageDetails>,
    fetchedUsers: Array as Prop<FetchedUsers[]>,
    associates: {} as Prop<UsersOnline>,

    associatesMap: Object,

    sendWSMessage: Function,
    clearFetchedUsers: Function,
    startCallSession: Function,
    joinCallSession: Function,
  },

  data: () => ({
    vuetify: vuetify,
    messageContent: "",
    newRoomName: "",
    searchUserName: "",

    showTextField: true,
    showAddUsersDialog: false,
    showOnlineUsersDialog: false,

    selectedUsersToAddToRoom: [] as string[],

    messageType: MessageType,
    userID: store.state.userID,
    userName: store.state.email,
  }),

  methods: {
    onScroll: function (e: { target: Element }) {
      const messages = this.currentViewedRoom.messages;
      if (
        e.target &&
        e.target.scrollTop < 100 &&
        messages.length > 0 &&
        messages[0].index > 1
      ) {
        this.loadMoreMessages();
      }
    },

    sendMessage: function () {
      if (!this.messageContent.match(/\S/)) return;

      const message = {
        msgType: WSMessageType.NewMessage,
        userID: this.userID,
        roomID: this.currentViewedRoom.roomID,
        message: this.messageContent,
        type: this.messageType.Message,
      };

      console.log(message);
      this.sendWSMessage(JSON.stringify(message));
      this.messageContent = "";
    },

    scrollToBottomOfChatPage: function () {
      setTimeout(() => {
        const scrollHeight = this.$el.querySelector("#messages");
        if (scrollHeight) {
          scrollHeight.scrollTop = scrollHeight.scrollHeight;
        }
      }, 0);
    },

    loadMoreMessages: function () {
      const message = {
        msgType: WSMessageType.RequestMessages,
        roomID: this.currentViewedRoom.roomID,
        skip: this.currentViewedRoom.messages.length - 1,
        limit: 15,
      };

      this.sendWSMessage(JSON.stringify(message));
    },

    searchUsers: function () {
      const message = {
        msgType: WSMessageType.SearchUser,
        searchText: this.searchUserName,
      };

      this.sendWSMessage(JSON.stringify(message));
    },

    requestUserToJoinRoom: function () {
      for (let i = 0; i < this.selectedUsersToAddToRoom.length; i++) {
        const message = {
          msgType: WSMessageType.RequestUsersToJoinRoom,
          userID: this.userID,
          roomID: this.currentViewedRoom.roomID,
          roomName: this.currentViewedRoom.roomName,
          userToJoinID: this.selectedUsersToAddToRoom[i],
        };

        this.sendWSMessage(JSON.stringify(message));
      }

      this.closeAddUserDialog();
    },

    closeAddUserDialog: function () {
      this.selectedUsersToAddToRoom = [];
      this.showAddUsersDialog = false;

      this.clearFetchedUsers();
    },

    exitRoom: function () {
      const message = {
        msgType: WSMessageType.ExitRoom,
        roomID: this.currentViewedRoom.roomID,
        userID: this.userID,
      };

      this.sendWSMessage(JSON.stringify(message));
      this.showOnlineUsersDialog = false;
    },
  },
});
</script>
