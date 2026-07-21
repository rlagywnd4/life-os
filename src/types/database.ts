export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          display_name: string | null;
          timezone: string;
          week_start_day: number;
          max_active_projects: number;
          max_core_actions: number;
          recommended_action_minutes: number;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["profiles"]["Row"]> & {
          id: string;
        };
        Update: Partial<Database["public"]["Tables"]["profiles"]["Row"]>;
        Relationships: [];
      };
      inbox_items: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          description: string | null;
          category: string;
          status: string;
          reviewed_at: string | null;
          converted_project_id: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["inbox_items"]["Row"]> & {
          title: string;
        };
        Update: Partial<Database["public"]["Tables"]["inbox_items"]["Row"]>;
        Relationships: [];
      };
      projects: {
        Row: {
          id: string;
          user_id: string;
          source_inbox_item_id: string | null;
          title: string;
          description: string | null;
          reason: string | null;
          desired_outcome: string | null;
          status: string;
          priority: number;
          started_at: string | null;
          target_date: string | null;
          completed_at: string | null;
          abandoned_reason: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["projects"]["Row"]> & {
          title: string;
        };
        Update: Partial<Database["public"]["Tables"]["projects"]["Row"]>;
        Relationships: [];
      };
      action_items: {
        Row: {
          id: string;
          user_id: string;
          project_id: string;
          parent_action_id: string | null;
          title: string;
          description: string | null;
          estimated_minutes: number;
          status: string;
          priority: number;
          scheduled_date: string | null;
          scheduled_time: string | null;
          due_date: string | null;
          completed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["action_items"]["Row"]> & {
          project_id: string;
          title: string;
        };
        Update: Partial<Database["public"]["Tables"]["action_items"]["Row"]>;
        Relationships: [];
      };
      daily_plans: {
        Row: {
          id: string;
          user_id: string;
          plan_date: string;
          energy_level: string;
          day_mode: string;
          note: string | null;
          rest_reason: string | null;
          available_minutes: number | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["daily_plans"]["Row"]> & {
          plan_date: string;
        };
        Update: Partial<Database["public"]["Tables"]["daily_plans"]["Row"]>;
        Relationships: [];
      };
      daily_plan_actions: {
        Row: {
          id: string;
          user_id: string;
          daily_plan_id: string;
          action_item_id: string;
          is_core: boolean;
          sort_order: number;
          result_status: string;
          reflection: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["daily_plan_actions"]["Row"]
        > & {
          daily_plan_id: string;
          action_item_id: string;
        };
        Update: Partial<
          Database["public"]["Tables"]["daily_plan_actions"]["Row"]
        >;
        Relationships: [];
      };
      calendar_events: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          description: string | null;
          event_date: string;
          start_time: string | null;
          end_time: string | null;
          is_all_day: boolean;
          category: "GENERAL" | "APPOINTMENT" | "TRAVEL" | "MILESTONE";
          location: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["calendar_events"]["Row"]
        > & { title: string; event_date: string };
        Update: Partial<Database["public"]["Tables"]["calendar_events"]["Row"]>;
        Relationships: [];
      };
      action_schedule_changes: {
        Row: {
          id: string;
          user_id: string;
          action_item_id: string;
          previous_date: string | null;
          previous_time: string | null;
          new_date: string | null;
          new_time: string | null;
          reason: string | null;
          created_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["action_schedule_changes"]["Row"]
        > & { action_item_id: string };
        Update: Partial<
          Database["public"]["Tables"]["action_schedule_changes"]["Row"]
        >;
        Relationships: [];
      };
      someday_items: {
        Row: {
          id: string;
          user_id: string;
          source_inbox_item_id: string | null;
          title: string;
          description: string | null;
          category: string;
          last_reviewed_at: string | null;
          archived_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["someday_items"]["Row"]
        > & { title: string };
        Update: Partial<Database["public"]["Tables"]["someday_items"]["Row"]>;
        Relationships: [];
      };
      weekly_reviews: {
        Row: {
          id: string;
          user_id: string;
          week_start_date: string;
          week_end_date: string;
          status: string;
          current_step: number;
          went_well: string | null;
          was_difficult: string | null;
          felt_closer_to_desired_life: string | null;
          do_less_next_week: string | null;
          next_week_direction: string | null;
          energy_summary: string | null;
          created_at: string;
          updated_at: string;
          completed_at: string | null;
        };
        Insert: Partial<
          Database["public"]["Tables"]["weekly_reviews"]["Row"]
        > & {
          week_start_date: string;
          week_end_date: string;
        };
        Update: Partial<Database["public"]["Tables"]["weekly_reviews"]["Row"]>;
        Relationships: [];
      };
      health_profiles: {
        Row: {
          id: string;
          user_id: string;
          height_cm: number | null;
          birth_year: number | null;
          current_weight_kg: number;
          target_weight_kg: number;
          goal_description: string | null;
          activity_level: string | null;
          usual_weigh_in_time: string | null;
          weekly_loss_rate_kg: number;
          weekday_brisk_walk_minutes: number;
          low_energy_walk_minutes: number;
          snack_reminder_enabled: boolean;
          snack_reminder_time: string;
          snack_weekdays: number[];
          default_snack_name: string;
          default_snack_note: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["health_profiles"]["Row"]
        > & {
          current_weight_kg: number;
          target_weight_kg: number;
        };
        Update: Partial<Database["public"]["Tables"]["health_profiles"]["Row"]>;
        Relationships: [];
      };
      health_weight_goals: {
        Row: {
          id: string;
          user_id: string;
          target_weight_kg: number;
          goal_name: string;
          sort_order: number;
          achieved: boolean;
          achieved_date: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["health_weight_goals"]["Row"]
        > & {
          target_weight_kg: number;
          goal_name: string;
        };
        Update: Partial<
          Database["public"]["Tables"]["health_weight_goals"]["Row"]
        >;
        Relationships: [];
      };
      health_check_ins: {
        Row: {
          id: string;
          user_id: string;
          check_in_date: string;
          weight_kg: number | null;
          steps: number | null;
          brisk_walk_status: string;
          planned_snack_done: boolean | null;
          unplanned_snack: boolean | null;
          dinner_overeating: boolean | null;
          free_meal: boolean | null;
          alcohol: boolean | null;
          exercise_completion: string;
          sleep_hours: number | null;
          condition_level: string | null;
          stress_level: string | null;
          low_energy_mode: boolean;
          note: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["health_check_ins"]["Row"]
        > & {
          check_in_date: string;
        };
        Update: Partial<
          Database["public"]["Tables"]["health_check_ins"]["Row"]
        >;
        Relationships: [];
      };
      life_context_documents: {
        Row: {
          id: string;
          user_id: string;
          version: string;
          title: string;
          source_date: string | null;
          purpose: string | null;
          privacy_level: string;
          content_markdown: string;
          metadata: Json;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["life_context_documents"]["Row"]
        > & {
          version: string;
          title: string;
          content_markdown: string;
        };
        Update: Partial<
          Database["public"]["Tables"]["life_context_documents"]["Row"]
        >;
        Relationships: [];
      };
      life_context_entries: {
        Row: {
          id: string;
          user_id: string;
          document_id: string;
          entry_key: string;
          title: string;
          category: string;
          privacy_level: string;
          content_markdown: string | null;
          data: Json;
          sort_order: number;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<
          Database["public"]["Tables"]["life_context_entries"]["Row"]
        > & {
          document_id: string;
          entry_key: string;
          title: string;
          category: string;
        };
        Update: Partial<
          Database["public"]["Tables"]["life_context_entries"]["Row"]
        >;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: {
      convert_inbox_to_project: {
        Args: {
          inbox_id: string;
          project_title: string;
          project_reason: string;
          project_desired_outcome: string;
          activate_now: boolean;
        };
        Returns: string;
      };
      add_core_action_to_today: {
        Args: {
          action_id: string;
          target_date: string;
          make_core: boolean;
        };
        Returns: string;
      };
      reschedule_action: {
        Args: {
          action_id: string;
          target_date: string;
          target_time?: string | null;
          change_reason?: string | null;
        };
        Returns: undefined;
      };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
