import React, { useState, useEffect } from 'react';
import { SafeAreaView, View, Text, TextInput, Button, StyleSheet } from 'react-native';
import * as Notifications from 'expo-notifications';
import axios from 'axios';

export default function App() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [ent, setEnt] = useState('');
  const [token, setToken] = useState(null);

  useEffect(() => {
    Notifications.requestPermissionsAsync();
  }, []);

  async function login() {
    try {
      const response = await axios.post('http://localhost:5000/login', {
        username,
        password,
        ent,
      });
      setToken(response.data.token);
    } catch (error) {
      console.error('Login failed', error);
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.form}>
        <Text style={styles.label}>Identifiant ENT</Text>
        <TextInput style={styles.input} value={username} onChangeText={setUsername} />
        <Text style={styles.label}>Mot de passe</Text>
        <TextInput style={styles.input} secureTextEntry value={password} onChangeText={setPassword} />
        <Text style={styles.label}>ENT</Text>
        <TextInput style={styles.input} value={ent} onChangeText={setEnt} />
        <Button title="Connexion" onPress={login} />
      </View>
      {token && <Text style={styles.success}>Connecté !</Text>}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 16,
  },
  form: {
    marginBottom: 20,
  },
  label: {
    marginVertical: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    padding: 8,
    borderRadius: 4,
  },
  success: {
    marginTop: 20,
    fontWeight: 'bold',
    color: 'green',
  },
});
