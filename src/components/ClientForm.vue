<script setup lang="ts">
import { ref, computed } from 'vue'

interface ClientData {
  contract: string
  clientName: string
  previousPlan: string
  previousValue: string
  currentPlan: string
  currentValue: string
}

const AVAILABLE_PLANS = [
  'PLANO COMBO 400 MEGA + FIXO LOCAL ILIMITADO',
  'PLANO COMBO DE 800 MEGA + 1 FIXO LOCAL ILIMITADO',
  'PLANO COMBO DE 400 MEGA + FIXO BRASIL ILIMITADO',
  'PLANO COMBO EMPRESARIAL 800 MEGA + 2 FIXOS BRASIL FIDELIZADO + UBOOK',
  'PLANO COMBO DE 800 MEGA + 2 FIXOS BRASIL ILIMITADO',
  'PLANO 400 MEGA FIDELIZADO',
  'PLANO COMBO DE 800 MEGA + 1 FIXO BRASIL ILIMITADO',
  'PLANO COMBO 1 GIGA + FIXO LOCAL ILIMITADO + DEEZER + HBO MAX + DR. AGE',
  'PLANO COMBO 1 GIGA + FIXO LOCAL ILIMITADO + DEEZER',
  'PLANO COMBO 1 GIGA + FIXO BRASIL ILIMITADO + DEEZER + HBO MAX + DR. AGE'
]

const formData = ref<ClientData>({
  contract: '',
  clientName: '',
  previousPlan: '',
  previousValue: '',
  currentPlan: '',
  currentValue: ''
})

const dataConfirmed = ref(false)

const showPreviousPlanSuggestions = ref(false)
const showCurrentPlanSuggestions = ref(false)

const previousPlanSuggestions = computed(() => {
  if (!formData.value.previousPlan) return []
  return AVAILABLE_PLANS.filter(plan => 
    plan.toLowerCase().includes(formData.value.previousPlan.toLowerCase())
  )
})

const currentPlanSuggestions = computed(() => {
  if (!formData.value.currentPlan) return []
  return AVAILABLE_PLANS.filter(plan => 
    plan.toLowerCase().includes(formData.value.currentPlan.toLowerCase())
  )
})

const selectPreviousPlan = (plan: string) => {
  formData.value.previousPlan = plan
  showPreviousPlanSuggestions.value = false
}

const selectCurrentPlan = (plan: string) => {
  formData.value.currentPlan = plan
  showCurrentPlanSuggestions.value = false
}

const handleSubmit = () => {
  if (!dataConfirmed.value) {
    alert('Por favor, confirme que os dados estão corretos antes de prosseguir.')
    return
  }
  console.log('Form submitted:', formData.value)
}
</script>

<template>
  <div class="form-container">
    <h2>Cadastrar Cliente</h2>
    
    <form @submit.prevent="handleSubmit">
      <div class="form-field">
        <label>Contrato</label>
        <input 
          type="text" 
          v-model="formData.contract"
        >
      </div>

      <div class="form-field">
        <label>Nome do cliente</label>
        <input 
          type="text" 
          v-model="formData.clientName"
        >
      </div>

      <div class="form-row">
        <div class="form-field">
          <label>Plano anterior</label>
          <div class="autocomplete">
            <input 
              type="text" 
              v-model="formData.previousPlan"
              @focus="showPreviousPlanSuggestions = true"
              @blur="setTimeout(() => showPreviousPlanSuggestions = false, 200)"
            >
            <div v-if="showPreviousPlanSuggestions && previousPlanSuggestions.length > 0" class="suggestions">
              <div 
                v-for="plan in previousPlanSuggestions" 
                :key="plan"
                class="suggestion-item"
                @mousedown="selectPreviousPlan(plan)"
              >
                {{ plan }}
              </div>
            </div>
          </div>
        </div>

        <div class="form-field">
          <label>Valor anterior</label>
          <input 
            type="text" 
            v-model="formData.previousValue"
          >
        </div>
      </div>

      <div class="form-row">
        <div class="form-field">
          <label>Plano atual</label>
          <div class="autocomplete">
            <input 
              type="text" 
              v-model="formData.currentPlan"
              @focus="showCurrentPlanSuggestions = true"
              @blur="setTimeout(() => showCurrentPlanSuggestions = false, 200)"
            >
            <div v-if="showCurrentPlanSuggestions && currentPlanSuggestions.length > 0" class="suggestions">
              <div 
                v-for="plan in currentPlanSuggestions" 
                :key="plan"
                class="suggestion-item"
                @mousedown="selectCurrentPlan(plan)"
              >
                {{ plan }}
              </div>
            </div>
          </div>
        </div>

        <div class="form-field">
          <label>Valor atual</label>
          <input 
            type="text" 
            v-model="formData.currentValue"
          >
        </div>
      </div>

      <div class="confirmation-checkbox">
        <label class="checkbox-label">
          <input 
            type="checkbox" 
            v-model="dataConfirmed"
          >
          <span>Confirmo que todos os dados estão corretos</span>
        </label>
      </div>

      <button 
        type="submit"
        :class="{ 'button-disabled': !dataConfirmed }"
        :disabled="!dataConfirmed"
      >
        Cadastrar refidelização
      </button>
    </form>
  </div>
</template>

<style scoped>
.form-container {
  background: white;
  padding: 2rem 2.5rem;
  border-radius: 12px;
  width: 500px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  border: 1px solid #e2e2e2;
}

h2 {
  text-align: center;
  color: #333;
  margin: 0 0 2rem;
  font-size: 1.25rem;
  font-weight: 600;
}

.form-field {
  margin-bottom: 1.25rem;
  width: 100%;
  position: relative;
}

.form-row {
  display: flex;
  gap: 1.25rem;
  margin-bottom: 1.25rem;
}

.form-row .form-field {
  margin-bottom: 0;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  color: #333;
  font-size: 0.875rem;
  font-weight: 500;
}

input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e2e2e2;
  border-radius: 6px;
  font-size: 0.875rem;
  background: #fafafa;
  box-sizing: border-box;
}

input:focus {
  outline: none;
  border-color: #d1d1d1;
  background: white;
}

button {
  width: 100%;
  padding: 0.875rem;
  margin-top: 0.5rem;
  background: #ff5722;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

button:hover {
  background: #f4511e;
}

button.button-disabled {
  background: #cccccc;
  cursor: not-allowed;
}

button.button-disabled:hover {
  background: #cccccc;
}

.autocomplete {
  position: relative;
  width: 100%;
}

.suggestions {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #e2e2e2;
  border-radius: 6px;
  margin-top: 4px;
  max-height: 200px;
  overflow-y: auto;
  z-index: 1000;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.suggestion-item {
  padding: 0.75rem;
  cursor: pointer;
  font-size: 0.875rem;
}

.suggestion-item:hover {
  background: #f5f5f5;
}

.confirmation-checkbox {
  margin: 1.5rem 0 1rem;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  user-select: none;
}

.checkbox-label input[type="checkbox"] {
  width: auto;
  cursor: pointer;
}

.checkbox-label span {
  color: #333;
  font-size: 0.875rem;
}
</style>