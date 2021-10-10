<template>
  <v-row class="fill-height">
    <v-col cols="12"></v-col>
    <v-col class="my-auto">
      <v-row>
        <v-col cols="4"> </v-col>
        <v-col cols="4">
          <v-card flat outlined shaped>
            <v-row class="mx-5 fill-height">
              <v-col cols="12">
                <v-card-text>
                  <b>Create New Room</b>
                </v-card-text>
              </v-col>

              <v-col cols="2"></v-col>
              <v-col cols="8">
                <v-text-field
                  @keyup.enter.exact="createNewRoom()"
                  placeholder="Room Name"
                  rounded
                  outlined
                  v-model="newRoomName"
                />
                <v-btn @click="createNewRoom()" text color="green"
                  >Create Room</v-btn
                >
              </v-col>
              <v-col cols="2"></v-col>
            </v-row> </v-card
        ></v-col>
        <v-col cols="4"> </v-col>
      </v-row>
    </v-col>
    <v-col cols="12"></v-col>
  </v-row>
</template>

<script lang="ts">
import Vue from "vue";

export default Vue.extend({
  name: "CreateRoom",

  props: {
    createRoom: Function,
  },

  data: () => ({
    newRoomName: "",
  }),

  methods: {
    createNewRoom: function () {
      this.createRoom(this.newRoomName);
    },
  },
});
</script>

<style>
</style>