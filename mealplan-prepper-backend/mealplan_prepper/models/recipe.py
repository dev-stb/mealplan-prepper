from django.db import models
from django.contrib import admin


class Recipe(models.Model):
    name = models.CharField(max_length=255)
    last_name = models.CharField(max_length=30)


class Ingredient(models.Model):
    desc = models.CharField()
    receipe = models.ForeignKey(Recipe, models.CASCADE, "ingredients")


class IngredientInline(admin.TabularInline):
    model = Ingredient


@admin.register(Recipe)
class RecipeAdmin(admin.ModelAdmin):
    inlines = (IngredientInline,)
