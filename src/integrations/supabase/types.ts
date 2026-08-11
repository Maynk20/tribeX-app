export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      activities: {
        Row: {
          amenities: string[]
          category: string
          cost_per_head: number
          created_at: string
          date_time: string
          deleted_at: string | null
          description: string
          host_id: string
          id: string
          image_url: string | null
          is_online: boolean
          is_urgent: boolean
          latitude: number | null
          location: string
          longitude: number | null
          meeting_link: string | null
          slots_left: number
          title: string
          topic_tags: string[]
          total_slots: number
          updated_at: string
          urgent_until: string | null
          verified_only: boolean
          women_only: boolean
        }
        Insert: {
          amenities?: string[]
          category: string
          cost_per_head?: number
          created_at?: string
          date_time: string
          deleted_at?: string | null
          description: string
          host_id: string
          id?: string
          image_url?: string | null
          is_online?: boolean
          is_urgent?: boolean
          latitude?: number | null
          location: string
          longitude?: number | null
          meeting_link?: string | null
          slots_left?: number
          title: string
          topic_tags?: string[]
          total_slots: number
          updated_at?: string
          urgent_until?: string | null
          verified_only?: boolean
          women_only?: boolean
        }
        Update: {
          amenities?: string[]
          category?: string
          cost_per_head?: number
          created_at?: string
          date_time?: string
          deleted_at?: string | null
          description?: string
          host_id?: string
          id?: string
          image_url?: string | null
          is_online?: boolean
          is_urgent?: boolean
          latitude?: number | null
          location?: string
          longitude?: number | null
          meeting_link?: string | null
          slots_left?: number
          title?: string
          topic_tags?: string[]
          total_slots?: number
          updated_at?: string
          urgent_until?: string | null
          verified_only?: boolean
          women_only?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "activities_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activities_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
        ]
      }
      auth_otps: {
        Row: {
          attempts: number
          code_hash: string
          created_at: string
          email: string
          expires_at: string
          id: string
          used_at: string | null
        }
        Insert: {
          attempts?: number
          code_hash: string
          created_at?: string
          email: string
          expires_at: string
          id?: string
          used_at?: string | null
        }
        Update: {
          attempts?: number
          code_hash?: string
          created_at?: string
          email?: string
          expires_at?: string
          id?: string
          used_at?: string | null
        }
        Relationships: []
      }
      blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
          id: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
          id?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "blocks_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocks_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      event_memories: {
        Row: {
          activity_id: string
          caption: string | null
          created_at: string
          id: string
          image_url: string
          user_id: string
        }
        Insert: {
          activity_id: string
          caption?: string | null
          created_at?: string
          id?: string
          image_url: string
          user_id: string
        }
        Update: {
          activity_id?: string
          caption?: string | null
          created_at?: string
          id?: string
          image_url?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_memories_activity_id_fkey"
            columns: ["activity_id"]
            isOneToOne: false
            referencedRelation: "activities"
            referencedColumns: ["id"]
          },
        ]
      }
      expense_shares: {
        Row: {
          amount: number
          created_at: string
          expense_id: string
          id: string
          paid_at: string | null
          status: Database["public"]["Enums"]["expense_share_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          expense_id: string
          id?: string
          paid_at?: string | null
          status?: Database["public"]["Enums"]["expense_share_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          expense_id?: string
          id?: string
          paid_at?: string | null
          status?: Database["public"]["Enums"]["expense_share_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "expense_shares_expense_id_fkey"
            columns: ["expense_id"]
            isOneToOne: false
            referencedRelation: "expenses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expense_shares_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expense_shares_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
        ]
      }
      expenses: {
        Row: {
          activity_id: string
          created_at: string
          created_by: string
          description: string
          id: string
          split_type: Database["public"]["Enums"]["expense_split_type"]
          total_amount: number
          updated_at: string
          upi_id: string | null
        }
        Insert: {
          activity_id: string
          created_at?: string
          created_by: string
          description: string
          id?: string
          split_type?: Database["public"]["Enums"]["expense_split_type"]
          total_amount: number
          updated_at?: string
          upi_id?: string | null
        }
        Update: {
          activity_id?: string
          created_at?: string
          created_by?: string
          description?: string
          id?: string
          split_type?: Database["public"]["Enums"]["expense_split_type"]
          total_amount?: number
          updated_at?: string
          upi_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "expenses_activity_id_fkey"
            columns: ["activity_id"]
            isOneToOne: false
            referencedRelation: "activities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expenses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expenses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
        ]
      }
      join_requests: {
        Row: {
          activity_id: string
          checked_in_at: string | null
          created_at: string
          id: string
          no_show: boolean
          status: Database["public"]["Enums"]["join_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          activity_id: string
          checked_in_at?: string | null
          created_at?: string
          id?: string
          no_show?: boolean
          status?: Database["public"]["Enums"]["join_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          activity_id?: string
          checked_in_at?: string | null
          created_at?: string
          id?: string
          no_show?: boolean
          status?: Database["public"]["Enums"]["join_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "join_requests_activity_id_fkey"
            columns: ["activity_id"]
            isOneToOne: false
            referencedRelation: "activities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "join_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "join_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          activity_id: string
          created_at: string
          id: string
          sender_id: string
          text: string
        }
        Insert: {
          activity_id: string
          created_at?: string
          id?: string
          sender_id: string
          text: string
        }
        Update: {
          activity_id?: string
          created_at?: string
          id?: string
          sender_id?: string
          text?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_activity_id_fkey"
            columns: ["activity_id"]
            isOneToOne: false
            referencedRelation: "activities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          activity_id: string | null
          body: string | null
          created_at: string
          id: string
          is_read: boolean
          join_request_id: string | null
          read_at: string | null
          related_user_id: string | null
          title: string
          type: string
          user_id: string
        }
        Insert: {
          activity_id?: string | null
          body?: string | null
          created_at?: string
          id?: string
          is_read?: boolean
          join_request_id?: string | null
          read_at?: string | null
          related_user_id?: string | null
          title: string
          type: string
          user_id: string
        }
        Update: {
          activity_id?: string | null
          body?: string | null
          created_at?: string
          id?: string
          is_read?: boolean
          join_request_id?: string | null
          read_at?: string | null
          related_user_id?: string | null
          title?: string
          type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_activity_id_fkey"
            columns: ["activity_id"]
            isOneToOne: false
            referencedRelation: "activities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_join_request_id_fkey"
            columns: ["join_request_id"]
            isOneToOne: false
            referencedRelation: "join_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      poll_votes: {
        Row: {
          created_at: string
          id: string
          option_index: number
          poll_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          option_index: number
          poll_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          option_index?: number
          poll_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "poll_votes_poll_id_fkey"
            columns: ["poll_id"]
            isOneToOne: false
            referencedRelation: "polls"
            referencedColumns: ["id"]
          },
        ]
      }
      polls: {
        Row: {
          activity_id: string
          closed_at: string | null
          created_at: string
          created_by: string
          id: string
          options: Json
          question: string
        }
        Insert: {
          activity_id: string
          closed_at?: string | null
          created_at?: string
          created_by: string
          id?: string
          options: Json
          question: string
        }
        Update: {
          activity_id?: string
          closed_at?: string | null
          created_at?: string
          created_by?: string
          id?: string
          options?: Json
          question?: string
        }
        Relationships: [
          {
            foreignKeyName: "polls_activity_id_fkey"
            columns: ["activity_id"]
            isOneToOne: false
            referencedRelation: "activities"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          city: string | null
          created_at: string
          full_name: string | null
          gender: string | null
          has_completed_onboarding: boolean
          has_completed_profile: boolean
          id: string
          interests: string[]
          is_verified: boolean
          latitude: number | null
          longitude: number | null
          notify_radius_km: number
          phone: string | null
          push_token: string | null
          rating: number
          reliability_score: number
          total_reviews: number
          updated_at: string
          username: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          city?: string | null
          created_at?: string
          full_name?: string | null
          gender?: string | null
          has_completed_onboarding?: boolean
          has_completed_profile?: boolean
          id: string
          interests?: string[]
          is_verified?: boolean
          latitude?: number | null
          longitude?: number | null
          notify_radius_km?: number
          phone?: string | null
          push_token?: string | null
          rating?: number
          reliability_score?: number
          total_reviews?: number
          updated_at?: string
          username?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          city?: string | null
          created_at?: string
          full_name?: string | null
          gender?: string | null
          has_completed_onboarding?: boolean
          has_completed_profile?: boolean
          id?: string
          interests?: string[]
          is_verified?: boolean
          latitude?: number | null
          longitude?: number | null
          notify_radius_km?: number
          phone?: string | null
          push_token?: string | null
          rating?: number
          reliability_score?: number
          total_reviews?: number
          updated_at?: string
          username?: string | null
        }
        Relationships: []
      }
      ratings: {
        Row: {
          badges: string[]
          comment: string | null
          created_at: string
          id: string
          plan_id: string
          rating: number
          reviewee_id: string
          reviewer_id: string
          updated_at: string
        }
        Insert: {
          badges?: string[]
          comment?: string | null
          created_at?: string
          id?: string
          plan_id: string
          rating: number
          reviewee_id: string
          reviewer_id: string
          updated_at?: string
        }
        Update: {
          badges?: string[]
          comment?: string | null
          created_at?: string
          id?: string
          plan_id?: string
          rating?: number
          reviewee_id?: string
          reviewer_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ratings_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "activities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ratings_reviewee_id_fkey"
            columns: ["reviewee_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ratings_reviewee_id_fkey"
            columns: ["reviewee_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ratings_reviewer_id_fkey"
            columns: ["reviewer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ratings_reviewer_id_fkey"
            columns: ["reviewer_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      profiles_public: {
        Row: {
          avatar_url: string | null
          full_name: string | null
          id: string | null
          is_verified: boolean | null
          rating: number | null
          reliability_score: number | null
          username: string | null
        }
        Insert: {
          avatar_url?: string | null
          full_name?: string | null
          id?: string | null
          is_verified?: boolean | null
          rating?: number | null
          reliability_score?: number | null
          username?: string | null
        }
        Update: {
          avatar_url?: string | null
          full_name?: string | null
          id?: string | null
          is_verified?: boolean | null
          rating?: number | null
          reliability_score?: number | null
          username?: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      accept_join_request: {
        Args: { _req_id: string }
        Returns: {
          activity_id: string
          checked_in_at: string | null
          created_at: string
          id: string
          no_show: boolean
          status: Database["public"]["Enums"]["join_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "join_requests"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      check_in_activity: {
        Args: { _activity_id: string; _lat: number; _lon: number }
        Returns: {
          distance_m: number
          status: string
        }[]
      }
      get_meeting_link: { Args: { _activity_id: string }; Returns: string }
      get_user_id_by_email: { Args: { _email: string }; Returns: string }
      has_activity_access: {
        Args: { _activity_id: string; _user_id: string }
        Returns: boolean
      }
      haversine_m: {
        Args: { lat1: number; lat2: number; lon1: number; lon2: number }
        Returns: number
      }
      is_activity_host: {
        Args: { _activity_id: string; _user_id: string }
        Returns: boolean
      }
      list_activity_join_profiles: {
        Args: { _activity_id: string }
        Returns: {
          activity_id: string
          avatar_url: string
          checked_in_at: string
          city: string
          full_name: string
          is_verified: boolean
          join_request_id: string
          latitude: number
          longitude: number
          no_show: boolean
          rating: number
          reliability_score: number
          requested_at: string
          status: Database["public"]["Enums"]["join_status"]
          total_reviews: number
          user_id: string
          username: string
        }[]
      }
      mark_no_show: {
        Args: { _req_id: string }
        Returns: {
          activity_id: string
          checked_in_at: string | null
          created_at: string
          id: string
          no_show: boolean
          status: Database["public"]["Enums"]["join_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "join_requests"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      delete_user_account: { Args: never; Returns: boolean }
      purge_old_read_notifications: { Args: never; Returns: number }
      recalculate_user_rating: {
        Args: { target_user_id: string }
        Returns: undefined
      }
      remove_join_request: {
        Args: { _req_id: string }
        Returns: {
          activity_id: string
          checked_in_at: string | null
          created_at: string
          id: string
          no_show: boolean
          status: Database["public"]["Enums"]["join_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "join_requests"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      expense_share_status: "pending" | "paid"
      expense_split_type: "equal" | "custom"
      join_status: "pending" | "accepted" | "rejected"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      expense_share_status: ["pending", "paid"],
      expense_split_type: ["equal", "custom"],
      join_status: ["pending", "accepted", "rejected"],
    },
  },
} as const
