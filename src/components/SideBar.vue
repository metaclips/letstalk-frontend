<template>
  <div>
    <v-card flat height="100vh" align="center" outlined width="max-content">
      <v-row class="fill-height">
        <v-col class="my-2" cols="12">
          <v-avatar>
            <img src="../assets/unilag.svg" alt="Unilag Logo" />
          </v-avatar>
        </v-col>

        <v-col cols="12">
          <v-row class="fill-height">
            <v-col cols="12">
              <v-badge
                bordered
                overlap
                :content="unreadRoomMessages"
                :value="unreadRoomMessages"
              >
                <v-btn
                  @click="onRoom"
                  :x-large="!$vuetify.breakpoint.smAndDown"
                  icon
                >
                  <v-icon
                    :x-large="!$vuetify.breakpoint.smAndDown"
                    :color="highlightedSidebarOption == 'Rooms' ? 'blue' : ''"
                    >mdi-message-outline</v-icon
                  >
                </v-btn>
              </v-badge>
            </v-col>

            <v-col class="my-2" cols="12">
              <v-btn
                :x-large="!$vuetify.breakpoint.smAndDown"
                @click="onAddRoom"
                icon
              >
                <v-icon
                  :color="highlightedSidebarOption == 'AddRoom' ? 'blue' : ''"
                  :x-large="!$vuetify.breakpoint.smAndDown"
                  >mdi-message-plus</v-icon
                >
              </v-btn>
            </v-col>

            <v-col class="my-2" cols="12">
              <v-badge
                bordered
                overlap
                :content="unreadNotifications"
                :value="unreadNotifications"
              >
                <v-btn
                  :x-large="!$vuetify.breakpoint.smAndDown"
                  @click="onNotification"
                  icon
                >
                  <v-icon
                    :color="
                      highlightedSidebarOption == 'Notifications' ? 'blue' : ''
                    "
                    :x-large="!$vuetify.breakpoint.smAndDown"
                    >mdi-bell-outline</v-icon
                  >
                </v-btn>
              </v-badge>
            </v-col>
          </v-row>
        </v-col>

        <v-col class="my-auto" cols="12">
          <v-row class="fill-height">
            <v-col class="my-2" cols="12">
              <v-btn
                :x-large="!$vuetify.breakpoint.smAndDown"
                @click="changeTheme"
                icon
              >
                <v-icon
                  :color="themeColor"
                  :x-large="!$vuetify.breakpoint.smAndDown"
                  >mdi-moon-waxing-crescent</v-icon
                >
              </v-btn>
            </v-col>

            <v-col class="my-2" cols="12">
              <v-btn :x-large="!$vuetify.breakpoint.smAndDown" icon>
                <v-icon :x-large="!$vuetify.breakpoint.smAndDown"
                  >mdi-cog</v-icon
                >
              </v-btn>
            </v-col>

            <v-col class="my-2" cols="12">
              <v-btn
                :x-large="!$vuetify.breakpoint.smAndDown"
                @click="logOff"
                icon
              >
                <v-icon :x-large="!$vuetify.breakpoint.smAndDown"
                  >mdi-power-standby</v-icon
                >
              </v-btn>
            </v-col>
          </v-row>
        </v-col>
      </v-row>
    </v-card>
  </div>
</template>

<script lang="ts">
import vuetify from "@/plugins/vuetify";
import Vue from "vue";

export default Vue.extend({
  name: "SideBar",

  props: {
    activateAddRoomDialog: Function,
    activateNotificationDialog: Function,
    deactivateAllDialogs: Function,
    showAvailableRooms: Function,

    highlightedSidebarOption: String,

    unreadRoomMessages: Number,
    unreadNotifications: Number,
  },

  data: () => ({
    themeColor: "",
    newRoomName: "",

    showAddRoomDialog: false,
  }),

  methods: {
    changeTheme: function () {
      console.log(this.themeColor, vuetify.framework.theme.dark);
      this.$vuetify.theme.dark = !vuetify.framework.theme.dark;
      if (this.$vuetify.theme.dark) {
        this.themeColor = "blue";
      } else {
        this.themeColor = "";
      }
    },

    onNotification: function () {
      this.activateNotificationDialog();
    },

    onRoom: function () {
      this.deactivateAllDialogs();
      this.showAvailableRooms();
    },

    onAddRoom: function () {
      this.activateAddRoomDialog();
    },

    logOff: function () {
      this.$store.commit("setToken", "");
      this.$router.push("/login");
    },
  },
});
</script>

<style>
</style>