import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/track.dart';

class SupabaseService {
  static const _url = 'https://mtsejlqnhpogtygtluyp.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10c2VqbHFuaHBvZ3R5Z3RsdXlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MDY0NjIsImV4cCI6MjA5NzE4MjQ2Mn0.0uqGz8LM_vluKOibRUNCE2iiFR0oauHm48j3i1_3LhM';

  static Future<void> initialize() async {
    print('DATABASE_LOG: New Supabase (core) initializing...');
    await Supabase.initialize(url: _url, anonKey: _anonKey);
    print('DATABASE_LOG: New Supabase (core) initialized.');
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Fetch songs from Supabase `songs` table with optional category filter
  Future<List<Track>> fetchSongs({int offset = 0, int limit = 50, String? category}) async {
    print('DATABASE_LOG: Entering fetchSongs (category: $category, offset: $offset)');
    try {
      var query = client.from('songs').select();
      if (category != null) query = query.eq('category', category);
      final response = await query.range(offset, offset + limit - 1).order('title');
      print('DATABASE_SONG_DATA (core fetchSongs): $response');
      return (response as List).map((e) => Track.fromSupabase(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('DATABASE_ERROR (fetchSongs): $e');
      rethrow;
    }
  }

  /// Search songs by title or artist
  Future<List<Track>> searchSongs(String query) async {
    print('DATABASE_LOG: Entering searchSongs (query: $query)');
    try {
      final response = await client
          .from('songs')
          .select()
          .or('title.ilike.%$query%,artist.ilike.%$query%')
          .limit(100);
      print('DATABASE_SONG_DATA (core searchSongs): $response');
      return (response as List).map((e) => Track.fromSupabase(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('DATABASE_ERROR (searchSongs): $e');
      rethrow;
    }
  }

  /// Delete all songs with category 'hindi'
  Future<void> deleteHindiSongs() async {
    print('DATABASE_LOG: Attempting to delete hindi songs...');
    try {
      final response = await client
          .from('songs')
          .delete()
          .eq('category', 'hindi');
      print('DATABASE_LOG: Delete request sent.');
    } catch (e) {
      print('DATABASE_ERROR (deleteHindiSongs): $e');
      rethrow;
    }
  }

  /// Get public URL for a file in songs-audio storage bucket
  String getAudioUrl(String filePath) {
    return client.storage.from('songs-audio').getPublicUrl(filePath);
  }

  /// List all files inside a folder via direct public URL pattern
  Future<List<Track>> fetchSongsFromFolder(String folderName) async {
    // Storage list API needs service_role key, anon key returns []
    // So we query songs table by audio_url pattern instead
    final encodedFolder = Uri.encodeComponent(folderName);
    final pattern = '%/songs-audio/$encodedFolder/%';

    final response = await client
        .from('songs')
        .select()
        .ilike('audio_url', pattern)
        .order('title');

    print('DATABASE_SONG_DATA (core folder response 1): $response');

    final fromTable = (response as List)
        .map((e) => Track.fromSupabase(e as Map<String, dynamic>))
        .toList();

    if (fromTable.isNotEmpty) return fromTable;

    // Fallback: also try matching by audio_url with raw folder name
    final response2 = await client
        .from('songs')
        .select()
        .ilike('audio_url', '%/$folderName/%')
        .order('title');

    print('DATABASE_SONG_DATA (core folder response 2): $response2');

    return (response2 as List)
        .map((e) => Track.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }
}
