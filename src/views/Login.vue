<template>
  <v-app>
    <v-main>
      <v-container fluid class="fill-height">
        <v-row fill-height>
          <v-col class="mx-auto" cols="12">
            <v-img
              class="mx-auto"
              src="../assets/unilag.svg"
              height="300"
              width="300"
              contain
            ></v-img>
          </v-col>

          <v-col cols="12">
            <v-form v-model="detailsValid">
              <v-row>
                <v-col class="mx-auto" cols="12">
                  <span v-if="isAdmin">Welcome Admin</span>
                  <span v-else
                    >Welcome to the University of Lagos chatting platform</span
                  >
                </v-col>

                <v-col class="mx-auto" cols="12" md="6">
                  <v-text-field
                    v-model="email"
                    outlined
                    filled
                    type="text"
                    :rules="emailRules"
                    name="email"
                    required
                    placeholder="Email Address"
                    :disabled="detailsDisabled"
                  ></v-text-field>

                  <v-text-field
                    type="password"
                    v-model="password"
                    outlined
                    filled
                    required
                    :rules="passwordRules"
                    name="password"
                    placeholder="Password"
                    :disabled="detailsDisabled"
                  ></v-text-field>

                  <v-alert
                    v-if="signinErrorDetails"
                    dense
                    outlined
                    type="error"
                  >
                    <strong>{{ signinErrorDetails }}</strong>
                  </v-alert>
                </v-col>

                <v-col class="mx-auto" cols="12">
                  <v-btn
                    class="mr-4"
                    @click="$router.push('/register')"
                    color="green"
                    tile
                    dark
                    >Register</v-btn
                  >
                  <v-btn
                    @click="loginUser()"
                    :disabled="detailsDisabled || !detailsValid"
                    tile
                    >Log in</v-btn
                  >
                </v-col>
              </v-row>
            </v-form>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </v-app>
</template>

<script lang="ts">
"use strict";

import Vue from "vue";
import Axios from "axios";

export default Vue.extend({
  name: "Login",

  props: {
    isAdmin: Boolean,
  },

  data: () => ({
    detailsValid: false,
    detailsDisabled: false,

    signinErrorDetails: "",
    password: "",
    email: "",

    emailRules: [
      (v: string) => !!v || "E-mail is required",
      (v: string) => /.+@.+\..+/.test(v) || "E-mail must be valid",
    ],
    passwordRules: [(v: string) => !!v || "Password is required"],
  }),

  methods: {
    loginUser: function () {
      console.log(this.$store.state.token);
      this.detailsDisabled = true;

      let url = "";
      if (this.isAdmin) {
        url = "/admin/login";
      } else {
        url = "/login";
      }

      Axios.post(process.env.VUE_APP_BACKEND_SERVER + url, {
        email: this.email,
        password: this.password,
      })
        .then((Response) => {
          console.log(Response.data.data);

          if (Response.status == 200) {
            console.log("login successfull");
            this.$store.commit("setToken", Response.data.data.token);
            this.$store.commit("setEmail", this.email);
            this.$store.commit("setWsTicket", Response.data.data.wsTicket);
            this.$store.commit("setUserID", Response.data.data.userID);

            this.$router.push("/");
            console.log(Response.data.data.token);
          }
        })
        .catch((Error) => {
          this.detailsDisabled = false;
          if (Error.response.data) {
            this.signinErrorDetails = Error.response.data.error;
          }
        });
    },
  },

  mounted() {
    if (this.$store.state.token !== "") {
      this.$router.push("/");
    }
  },
});
</script>